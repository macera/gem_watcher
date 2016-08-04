# == Schema Information
#
# Table name: entries
#
#  id            :integer          not null, primary key
#  title         :string
#  published     :datetime
#  content       :text
#  url           :string
#  author        :string
#  plugin_id     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  major_version :integer
#  minor_version :integer
#  patch_version :string
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
  belongs_to :plugin

  has_many :dependencies, dependent: :destroy
  # has_many :plugins, through: :dependencies

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
    joins(:plugin).merge(Plugin.described).distinct.where.not('plugins.name' => 'rails').where('published' => Entry.select('max(published), plugin_id').group('plugin_id').pluck('max(published)')).order('entries.published desc')
  }


  # 許可するカラムの名前をオーバーライドする
  def self.ransackable_attributes(auth_object = nil)
    %w()
  end

  # def self.runtime_dependency
  #   all.each do |entry|
  #     next if entry.dependencies.present?
  #     p entry.title
  #     entry.create_dependencies
  #   end
  # end

  # def create_dependencies

  #   p 'gem:' + plugin.name

  #   # gem名を取得
  #   result = Gems.dependencies([plugin.name])
  #   # gem情報を取得
  #   return unless result
  #   hash = result.find {|h| h[:number] == version }
  #   # もしdependenciesが空であればリターン
  #   return unless hash
  #   return if hash[:dependencies].blank?

  #   p hash[:dependencies]

  #   hash[:dependencies].each do |target|
  #     plugin = Plugin.find_by(name: target[0])
  #     next unless plugin
  #     self.dependencies.find_or_create_by!(requirements: target[1], plugin: plugin)
  #   end

  # rescue => e
  #   binding.pry
  #   p e

  # end

  # versionを返す
  def version
    if minor_version && patch_version
      "#{major_version.to_s}.#{minor_version.to_s}.#{patch_version}"
    elsif minor_version
      "#{major_version.to_s}.#{minor_version.to_s}"
    else
      "#{major_version.to_s}"
    end
  end

  # 許可する関連の配列をオーバーライドする
  # def self.ransackable_associations(auth_object = nil)
  #   reflect_on_all_associations.map { |a| a.name.to_s }
  # end

end
