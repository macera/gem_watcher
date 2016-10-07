# == Schema Information
#
# Table name: project_versions
#
#  id               :integer          not null, primary key
#  newest           :string
#  installed        :string
#  pre              :string
#  project_id       :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  requested        :string
#  major_version    :integer
#  minor_version    :integer
#  patch_version    :integer
#  described        :boolean
#  plugin_id        :integer
#  entry_id         :integer
#  vulnerability    :boolean
#  revision_version :string
#
# Indexes
#
#  index_project_versions_on_entry_id    (entry_id)
#  index_project_versions_on_plugin_id   (plugin_id)
#  index_project_versions_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_05dec520fc  (plugin_id => plugins.id)
#  fk_rails_4bb073e287  (entry_id => entries.id)
#  fk_rails_eee5ff31fd  (project_id => projects.id)
#

class ProjectVersion < ActiveRecord::Base
  include Versioning
  include DisplayVersion
  extend  DisplayVersion

  belongs_to :project
  belongs_to :plugin
  belongs_to :entry

  attr_accessor :plugin_name # 画面表示用

  # 画面登録時のみ
  with_options unless: :plugin do
    validates :plugin_name, presence: true
    validates :plugin_name, length: { maximum: 50 }, allow_blank: true
    validates :plugin_name, format: { with: /\A[a-z0-9\._-]+\z/i }, allow_blank: true
    # rubygemに登録されているgem以外もあるためコメント
    #validate  :exist_rubygem
  end
  validates :installed, presence: true
  validates :installed, length: { maximum: 20 }, allow_blank: true
  validates :installed, format: { with: /\A[a-z0-9\.\s]+\z/i }, allow_blank: true

  validates :requested, length: { maximum: 20 }, allow_blank: true
  validates :requested, format: { with: /\A[0-9\.=~><\s]+\z/i }, allow_blank: true

  after_initialize  :set_plugin_name
  before_save       :set_versions
  after_validation  :with_plugin_info, unless: :plugin
  after_destroy     :destroy_with_plugin_name

  #scope :production, -> { where(group_type: nil) }
  scope :newest_versions,  -> { where.not(newest: nil) }
  scope :updated_versions, -> { where(newest: nil) }
  scope :only_gemfile,     -> { where(described: true) }
  scope :no_gemfile,       -> { where(described: false) }
  scope :vulnerable,       -> { where(vulnerability: true) }
  scope :updatable, -> {
    only_gemfile.newest_versions.order_by_version
    #where(described: true).less_than(version).order_by_version
  }
  # 引数のバージョンより低いものを取得する
  # scope :less_than, ->(version) {
  #   v = split_version(version)
  #   major = v[0].to_i
  #   minor = v[1].to_i
  #   patch = v[2].to_i
  #   revision = v[3].to_s
  #   where(["
  #     (major_version < ?) OR
  #     (major_version = ? AND minor_version < ?) OR
  #     (major_version = ? AND minor_version = ? AND patch_version < ?) OR
  #     (major_version = ? AND minor_version = ? AND patch_version = ? AND COALESCE(revision_version, '') < ?)",
  #    major,
  #    major, minor,
  #    major, minor, patch,
  #    major, minor, patch, revision
  #  ])
  # }

  # 指定で同じメジャーバージョンで自分より小さいマイナーバージョンはある時
  # そのマイナーバージョン系列の更新可能なプロジェクトバージョンを取得する
  # 4.2系の場合(4.1系が指定されてある)、4.2系バージョンを取得する
  scope :less_than_patch, ->(version) {
    v = split_version(version)
    major = v[0].to_i
    minor = v[1].to_i
    patch = v[2].to_i
    revision = v[3].to_s
    where(["
      (major_version = ? AND minor_version = ? AND patch_version < ?) OR
      (major_version = ? AND minor_version = ? AND patch_version = ? AND (CASE WHEN revision_version IS NOT null then regexp_replace(revision_version, '[a-zA-Z]+', '0', 'g') ELSE '' END) < ?)",
     major, minor, patch,
     major, minor, patch, revision
   ])
  }

  # 指定のメジャーバージョンの更新可能なプロジェクトバージョンを取得する
  # 5系の場合、5系バージョンを取得する
  scope :less_than_minor, ->(version) {
    v = split_version(version)
    major = v[0].to_i
    minor = v[1].to_i
    patch = v[2].to_i
    revision = v[3].to_s
    where(["
      (major_version = ? AND minor_version < ?) OR
      (major_version = ? AND minor_version = ? AND patch_version < ?) OR
      (major_version = ? AND minor_version = ? AND patch_version = ? AND (CASE WHEN revision_version IS NOT null then regexp_replace(revision_version, '[a-zA-Z]+', '0', 'g') ELSE '' END) < ?)",
      major, minor,
      major, minor, patch,
      major, minor, patch, revision
    ])
  }

  # 指定で最も小さい系列で更新可能なプロジェクトバージョンを取得する
  # 3系の場合、3系、2系、1系バージョンを取得する
  scope :less_than_major, ->(version) {
    v = split_version(version)
    major = v[0].to_i
    minor = v[1].to_i
    patch = v[2].to_i
    revision = v[3].to_s
    where(["
      (major_version < ?) OR
      (major_version = ? AND minor_version < ?) OR
      (major_version = ? AND minor_version = ? AND patch_version < ?) OR
      (major_version = ? AND minor_version = ? AND patch_version = ? AND (CASE WHEN revision_version IS NOT null then regexp_replace(revision_version, '[a-zA-Z]+', '0', 'g') ELSE '' END) < ?)",
      major,
      major, minor,
      major, minor, patch,
      major, minor, patch, revision
    ])
  }

  scope :order_by_version, -> {
    order("major_version desc, minor_version desc, patch_version desc, CASE WHEN revision_version IS NOT null then regexp_replace(revision_version, '[a-zA-Z]+', '0') ELSE NULL END desc NULLS LAST")
  }

  # 親gemのバージョンをもとにバージョンを取得する
  # 引数: 親のentry
  scope :by_parent_version, ->(entry) {
    where(project_id: entry.plugin.project_versions.where(entry_id: entry.id).pluck(:project_id)).order_by_version
  }

  scope :uniq_vulnerable_versions, -> {
    vulnerable.select(:entry_id, :plugin_id, :installed).uniq
  }

  # 脆弱性フラグを登録する
  def self.update_vulnerable_versions
    ProjectVersion.only_gemfile.each do |project_version|
      begin
        if project_version.security_alert?
          project_version.vulnerability = true
        else
          project_version.vulnerability = false
        end
        project_version.save! if project_version.changed?
      rescue => e
        CronLog.error_create(
          table_name: self.class.to_s.underscore,
          content: "メソッド:update_vulnerable_versions 詳細:#{e}"
        )
      end
    end
  end

  def security_check
    if entry.vulnerable_entries.present?
      return [self]
    end
    alert_versions = []
    entry.dependencies.joins(:plugin).includes(:plugin).each do |dependency|
        project_version = project.project_versions.joins(:plugin).where('plugins.id' => dependency.plugin.id).first
        result = project_version.security_check if project_version
        alert_versions << result.first if result.present?
    end
    return alert_versions.uniq
  end

  def alert_status
    if entry.vulnerable_entries.present?
      return 'red'
    end
    entry.dependencies.joins(:plugin).includes(:plugin).each do |dependency|
      project_version = project.project_versions.joins(:plugin).where('plugins.id' => dependency.plugin.id).first
      result = project_version.security_alert? if project_version
      return 'yellow' if result.present?
    end
    return ''
  end

  # このバージョン(とそのdependenciesのバージョン)に脆弱性があるか
  def security_alert?
    if entry.vulnerable_entries.present?
      return true
    end
    entry.dependencies.joins(:plugin).includes(:plugin).each do |dependency|
      project_version = project.project_versions.joins(:plugin).where('plugins.id' => dependency.plugin.id).first
      result = project_version.security_alert? if project_version
      return true if result
    end
    return false
  end

  private

  # callback
    # 画面表示用の値をセットする
    def set_plugin_name
      if plugin
        self.plugin_name = plugin_name || plugin.name
      end
    end

    # installedを細かいバージョンカラムにセットする
    def set_versions
      return unless installed
      version = split_version(installed)
      # TODO: entryのみに持たせるようにしたい
      v = skip_alphabetic_version_to_next(version)
      self.major_version    = v[0]
      self.minor_version    = v[1]
      self.patch_version    = v[2]
      self.revision_version = v[3]
    end

    # 画面登録・更新時で登録する項目のセット(cronは除く)
    def with_plugin_info
      if self.errors.empty?# && self.project.errors.empty?
        self.newest = newest_version
        # pluginの登録
        new_plugin = Plugin.find_or_initialize_by(name: plugin_name)
        # gem情報更新
        new_plugin.get_gem_uri
        new_plugin.save! if new_plugin.changed?
        self.plugin = new_plugin

        # TODO: gemの依存gemも登録しないといけない！！

        unless entry
          if installed
            Entry.update_list(new_plugin)
            version = split_version(installed)
            entry = plugin.entries.where(major_version: version[0],
                                         minor_version: version[1],
                                         patch_version: version[2],
                                         revision_version: version[3]
            ).first
            self.entry = entry
          end
        end

      end
    end

    # versionが1件もないpluginの場合削除する
    def destroy_with_plugin_name
      target_gem = plugin
      if target_gem.project_versions.blank?
        target_gem.update_dependencies # 依存情報を更新
        target_gem.destroy
      end
    end

    # newestを取得する
    def newest_version
      gem_info = Gems.info(plugin_name)
      if gem_info.is_a?(Hash)
        if gem_info['version'] != installed
          return gem_info['version']
        end
      end
    end

  # バリデーション

    # gem存在チェック
    # def exist_rubygem
    #   gem_info = Gems.info(plugin_name)
    #   unless gem_info.is_a?(Hash)
    #     errors.add(:plugin_name, :not_exist_rubygem)
    #   end
    # end

  # def self.ransackable_scopes(auth_object = nil)
  # end

end
