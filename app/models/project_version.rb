# == Schema Information
#
# Table name: project_versions
#
#  id         :integer          not null, primary key
#  newest     :string
#  installed  :string
#  pre        :string
#  project_id :integer
#  plugin_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  requested  :string
#
# Indexes
#
#  index_project_versions_on_plugin_id   (plugin_id)
#  index_project_versions_on_project_id  (project_id)
#

class ProjectVersion < ActiveRecord::Base
  belongs_to :project
  belongs_to :plugin

  attr_accessor :plugin_name # 画面表示用

  # 画面登録時のみ
  with_options unless: :plugin do
    validates :installed, presence: true
    validates :installed, length: { maximum: 20 }, allow_blank: true
    validates :installed, format: { with: /\A[a-z0-9.\s]+\z/i }, allow_blank: true
    validates :requested, length: { maximum: 20 }, allow_blank: true
    validates :requested, format: { with: /\A[0-9.=~><\s]+\z/i }, allow_blank: true
    validates :plugin_name, presence: true
    validates :plugin_name, length: { maximum: 50 }, allow_blank: true
    validates :plugin_name, format: { with: /\A[a-z0-9_-]+\z/i }, allow_blank: true
    validate  :exist_rubygem
  end

  after_initialize  :set_plugin_name
  after_validation :with_plugin_info, unless: :plugin
  after_destroy     :destroy_with_plugin_name

  #scope :production, -> { where(group_type: nil) }
  scope :newest_versions, -> { where.not(newest: nil) }
  scope :updated_versions, -> { where(newest: nil) }

  private

    def valid_plugin_format?
      plugin_name && plugin_name =~ /\A[a-z0-9_-]+\z/i
    end

  # callback

    # 画面表示用の値をセットする
    def set_plugin_name
      if plugin
        self.plugin_name = plugin.name
      end
    end

    # 画面登録・更新時、バックエンドで登録する項目のセット
    def with_plugin_info
      if plugin_name
        self.newest = newest_version
        # pluginの登録
        new_plugin = Plugin.find_or_create_by(name: plugin_name) do |pl|
          # gem情報取得
          pl.get_gem_uri if valid_plugin_format?
        end
        self.plugin = new_plugin
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
      return unless valid_plugin_format?
      gem_info = Gems.info(plugin_name)
      if gem_info.is_a?(Hash)
        if gem_info['version'] != installed
          return gem_info['version']
        end
      end
    end

  # バリデーション

    # gem存在チェック
    def exist_rubygem
      return unless valid_plugin_format?
      gem_info = Gems.info(plugin_name)
      unless gem_info.is_a?(Hash)
        errors.add(:plugin_name, :not_exist_rubygem)
      end
    end

  # def self.ransackable_scopes(auth_object = nil)
  # end

end
