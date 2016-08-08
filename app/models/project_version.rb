# == Schema Information
#
# Table name: project_versions
#
#  id            :integer          not null, primary key
#  newest        :string
#  installed     :string
#  pre           :string
#  project_id    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  requested     :string
#  major_version :integer
#  minor_version :integer
#  patch_version :string
#  described     :boolean
#  plugin_id     :integer
#  entry_id      :integer
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

  def security_check
    if SecurityAdvisory.check_gem(plugin, installed).present?
      return [self]
    end
    alert_versions = []
    entry.dependencies.each do |dependency|
      if dependency.plugin
        project_version = project.project_versions.joins(:plugin).where('plugins.name' => dependency.plugin.name).first
        result = project_version.security_check if project_version
        alert_versions << result.first if result.present?
      end
    end
    return alert_versions.uniq
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
      version = installed.scan(/(\d+)\.(\d+)\.(\S+)/).first # 0.0.0
      version = installed.scan(/(\d+)\.(\d+)/).first unless version # 0.0
      version = installed.scan(/(\d+)/).first unless version # 0
      self.major_version = version[0]
      self.minor_version = version[1]
      self.patch_version = version[2]
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

        # gemの依存gemも登録しないといけない！！

        unless entry
          if installed
            Entry.update_all(new_plugin)
            version = split_version(installed)
            entry = plugin.entries.where(major_version: version[0],
                                         minor_version: version[1],
                                         patch_version: version[2]
            ).first
            self.entry = entry
          end
        end

        # TODO: 依存情報かどうか選択できるようにする
        # 画面で登録したものはGemfileと見なす
        self.described = true if described.nil?
      end
    end

    # versionが1件もないpluginの場合削する
    def destroy_with_plugin_name
      target_gem = plugin
      if target_gem.project_versions.blank?
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

    # TODO: 共通化する
    def split_version(string)
      # 0.0.0
      version = string.scan(/(\d+)\.(\d+)\.(\S+)/).first
      # 0.0
      unless version
        version = string.scan(/(\d+)\.(\d+)/).first
      end
      # 0
      unless version
        version = string.scan(/(\d+)/).first
      end
      return version
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
