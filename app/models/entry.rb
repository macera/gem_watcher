# == Schema Information
#
# Table name: entries
#
#  id               :integer          not null, primary key
#  title            :string
#  published        :datetime
#  content          :text
#  url              :string
#  author           :string
#  plugin_id        :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  major_version    :integer
#  minor_version    :integer
#  patch_version    :integer
#  revision_version :string
#
# Indexes
#
#  index_entries_on_plugin_id  (plugin_id)
#
# Foreign Keys
#
#  fk_rails_bbb581ce25  (plugin_id => plugins.id)
#

class Entry < ActiveRecord::Base
  include Versioning

  belongs_to :plugin
  has_one    :project_version
  has_many   :dependencies, dependent: :destroy

  has_one :latest_entry_in_requirement
  has_one :target_dependency, through: :latest_entry_in_requirement,
                                source: 'dependency'

  has_many :patched_entries
  has_many :patched_securities, through: :patched_entries,
                                source: 'security_advisory'

  has_many :vulnerable_entries
  has_many :vulnerable_securities, through: :vulnerable_entries,
                                   source: 'security_advisory'

  validates :major_version, numericality: { only_integer: true }, allow_blank: true
  validates :minor_version, numericality: { only_integer: true }, allow_blank: true
  validates :patch_version, numericality: { only_integer: true }, allow_blank: true

  before_validation :set_versions

  #after_destroy :create_destroyed_table_log

  # rails リリースタイトル一覧
  scope :rails_entries, -> {

    entries = joins(:plugin).where('plugins.name' => 'rails')

    conditions = [[]]
    conditions[0] << '(major_version > ?)' #rails5以上は表示する
    conditions << Settings.rails_releases.last.major
    Settings.rails_releases.each do |v|
      if v.minor
        conditions[0] << "(major_version = ? AND (minor_version between ? AND ?))"
        conditions << v.major
        conditions << v.minor
        conditions << 9 # 最大のマイナーバージョン
      else
        version = entries.where(major_version: v.major).maximum('minor_version')
        conditions[0] << "(major_version = ? AND minor_version = ?)"
        conditions << v.major
        conditions << version
      end
    end
    conditions[0] = conditions[0].join(' OR ')

    entries.where('published' => Entry.select('max(published), major_version, minor_version, plugin_id').group('major_version', 'minor_version', 'plugin_id').having(conditions).pluck('max(published)')).order('published desc')
  }

  # scope :rails_entries, -> {
  #   joins(:plugin).where('plugins.name' => 'rails').where('published' => Entry.select('max(published), major_version, minor_version, plugin_id').group('major_version', 'minor_version', 'plugin_id').pluck('max(published)')).order('published desc').limit(4)
  # }

  # rails以外のgem リリースタイトル一覧 / Gemfileに書かれているgemのみ
  scope :newest_plugins, -> {
    joins(:plugin).includes(:plugin).merge(Plugin.described)
    .distinct.where.not('plugins.name' => 'rails')
    .where('published' => Entry.select('max(published), plugin_id')
                         .group('plugin_id').pluck('max(published)')).order('entries.published desc')
  }

  # patchバージョンを正しく並び替える(英字を含む場合もあるため)
  # string_to_arrayは、PostgreSQL9.1からはnullの場合空配列を返す
  # plugin: raindrops, version: 0.12.0.5.g821b
  scope :order_by_version, -> {
    order("major_version desc, minor_version desc, patch_version desc, CASE WHEN revision_version IS NOT null then regexp_replace(revision_version, '[a-zA-Z]+', '0') ELSE NULL END desc NULLS LAST")
  }

  # 許可するカラムの名前をオーバーライドする
  def self.ransackable_attributes(auth_object = nil)
    %w()
  end

  def self.update_list(plugin)
    # TODO: rubygemに登録されていないgem フラグをもたせるようにしたい
    gem_info = Gems.info(plugin.name)
    return unless gem_info.is_a?(Hash)

    # TODO: RSSだとprereleaseフラグが取れないので、APIの方で取得する
    path = URI.join("#{Settings.feeds.rubygem}#{plugin.name}/versions.atom")
    content = Feedjira::Feed.fetch_and_parse(path.to_s)

    content.entries.each do |entry|
      version = version_from_feed(entry.title)
      # beta版、ruby以外のplatform等は除く 例: 2.0rc0 5.0.0.rc1
      next unless version
      next if version.join('.') =~ /-|alpha|beta|rc|racecar|pre/   #|b\d

      local_entry = plugin.entries.where(title: entry.title).first_or_initialize
      local_entry.update_attributes!(
        content: entry.content,
        author: entry.author,
        url: entry.entry_id,
        published: entry.published,
        # major_version: v[0],
        # minor_version: v[1],
        # patch_version: v[2],
        # revision_version: v[3],
      )
    end
  rescue => e
  rescue => e
    CronLog.error_create(
      table_name: 'entry',
      content: "Gem名:#{plugin.name}, パス:#{path.to_s}, 詳細:#{e}"
    )
  end

  # titleからversionを取り出す(配列)
  def self.version_from_feed(title)
    # 0.0.0.0
    version = title.scan(/\S+\s\((\d+)\.(\d+)\.(\d+)\.(\S+)\)/).first
    # 0.0.0
    unless version
      version = title.scan(/\S+\s\((\d+)\.(\d+)\.(\S+)\)/).first
    end
    # 0.0
    unless version
      version = title.scan(/\S+\s\((\d+)\.(\d+)\)/).first
    end
    # 0
    unless version
      version = title.scan(/\S+\s\((\d+)\)/).first
    end
    version
  end

  # def self.sort_by_gem_version(versions)
  #   versions.sort {|a, b| Gem::Version.new(b.version) <=> Gem::Version.new(a.version) }
  # end

  def updatable_project_versions_by_series(entries)
    less_than_minor_version = less_than_minor_version?(entries)
    least_major_version = least_major_version?(entries)
    if less_than_minor_version
      return plugin.project_versions.less_than_patch(version)
    else
      if least_major_version
        return plugin.project_versions.less_than_major(version)
      else
        return plugin.project_versions.less_than_minor(version)
      end
    end
  end

  # 同じメジャーバージョンで自分より小さいマイナーバージョンはあるか?
  # 引数: 各バージョン系列の最新バージョン
  def less_than_minor_version?(entries)
    result = false
    entries.each do |e|
      if e != self && e.major_version == major_version && e.minor_version < minor_version
        result = true
      end
    end
    result
  end

  # 最も小さいメジャーバージョンか？
  # 引数: 各バージョン系列の最新バージョン
  def least_major_version?(entries)
    result = true
    entries.each do |e|
      if e != self && e.major_version < major_version
        result = false
      end
    end
    result
  end

  # def all_security_alert
  #   return true if vulnerable_entries.present?

  #   # このentryのdependenciesのすべてのentryを取り出す
  #   entries = all_entry
  #   if entries.present?
  #     result = Entry.where(id: entries).joins(:vulnerable_entries).includes(:vulnerable_entries).select('vulnerable_entries.id')
  #     return result.present?
  #   end
  # end

  # def all_entry
  #   entries = []
  #   dependencies.joins(:latest_entry).includes(:latest_entry).select('entries.id').each do |dependency|
  #     entry = dependency.latest_entry
  #     #if entry
  #       entries << entry.id
  #       entries += entry.all_entry
  #     #end
  #   end
  #   entries.uniq
  # end

  # 自身の脆弱性の有無を返す
  # def security_alert
  #   return true if vulnerable_entries.present?
  #   dependencies.joins(:latest_entry).includes(:latest_entry).select('entries.id').each do |dependency|
  #     entry = dependency.latest_entry
  #     return true if entry.security_alert
  #   end
  #   return false
  # end

  # versionを返す
  def version
    if minor_version && patch_version && revision_version
      "#{major_version.to_s}.#{minor_version.to_s}.#{patch_version}.#{revision_version}"
    elsif minor_version && revision_version
      # 英字入りバージョン対策
      "#{major_version.to_s}.#{minor_version.to_s}.#{revision_version}"
    elsif minor_version && patch_version
      "#{major_version.to_s}.#{minor_version.to_s}.#{patch_version}"
    elsif minor_version
      "#{major_version.to_s}.#{minor_version.to_s}"
    else
      "#{major_version.to_s}"
    end
  end

  private
    def set_versions
      version = version_from_feed
      if version.present?
        v = skip_alphabetic_version_to_next(version)
        self.major_version = v[0]
        self.minor_version = v[1]
        self.patch_version = v[2]
        self.revision_version = v[3]
      end
    end

      # titleからversionを取り出す(配列)
  def version_from_feed
    return if title.blank?
    # 0.0.0.0
    version = title.scan(/\S+\s\((\d+)\.(\d+)\.(\d+)\.(\S+)\)/).first
    # 0.0.0
    unless version
      version = title.scan(/\S+\s\((\d+)\.(\d+)\.(\S+)\)/).first
    end
    # 0.0
    unless version
      version = title.scan(/\S+\s\((\d+)\.(\d+)\)/).first
    end
    # 0
    unless version
      version = title.scan(/\S+\s\((\d+)\)/).first
    end
    version
  end

  # 12時間以内のセキュリティ情報の数
  # def security_count_in_same_day
  #   plugin.security_entries.where(published: (published.ago(43200))..(published.since(43200)) ).count
  # end

  # 許可する関連の配列をオーバーライドする
  # def self.ransackable_associations(auth_object = nil)
  #   reflect_on_all_associations.map { |a| a.name.to_s }
  # end

  # 削除ログ
  # def create_destroyed_table_log
  #   CronLog.success_table(self.class.to_s.underscore, title, :delete)
  # end

end
