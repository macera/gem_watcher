# == Schema Information
#
# Table name: plugins
#
#  id              :integer          not null, primary key
#  name            :string
#  newest          :string
#  pre             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  source_code_uri :string
#  homepage_uri    :string
#

class Plugin < ActiveRecord::Base
  has_many :project_versions
  has_many :projects, through: :project_versions
  has_many :entries, dependent: :destroy
  has_many :security_entries, dependent: :destroy
  has_many :security_advisories, dependent: :destroy

  has_one :dependency, dependent: :destroy

  validates :name, presence: true
  # validates :name, length: { maximum: 50 }, allow_blank: true
  # validates :name, format: { with: /\A[a-z0-9\._-]+\z/i }, allow_blank: true

  # gem更新画面のみ
  #validates :source_code_uri, presence: true, on: :update
  # validates :source_code_uri, length: { maximum: 200 }, allow_blank: true
  # validates :source_code_uri, format: {
  #                               with: /\A#{URI::regexp(%w(http https))}\/\z/,
  #                               message: "はURL形式で入力して下さい。末尾は/で終了する必要があります。"
  #                             },
  #                             allow_blank: true

  #before_destroy :destroy_relatitons

  after_create  :create_created_table_log
  after_update  :create_updated_table_log
  after_destroy :create_destroyed_table_log


  scope :described, -> {
    joins(:project_versions).merge(ProjectVersion.only_gemfile)
  }

  #scope :production, -> { joins(:project_versions).merge(ProjectVersion.production).uniq }

  # 許可するカラムの名前をオーバーライドする
  def self.ransackable_attributes(auth_object = nil)
    %w(name)
  end

  # 依存情報を登録する
  def self.create_runtime_dependencies
    self.all.each do |plugin|
      # gem名を取得
      plugin.create_runtime_dependency
    end
    return true
  end

  def create_runtime_dependency
    result = Gems.dependencies([name])
    return unless result
    entries.each do |entry|
      #return if entry.dependencies.present?
      hash = result.find {|h| h[:number] == entry.version && h[:platform] == 'ruby' }
      # もしdependenciesが空であればリターン
      return unless hash
      return if hash[:dependencies].blank?
      hash[:dependencies].each do |target|
        plugin = Plugin.find_by(name: target[0])
        if plugin
          # 存在しなかったpluginが後から登録された場合
          dependency = entry.dependencies.where(
                                requirements: target[1],
                                provisional_name: plugin.name).first
          if dependency
            dependency.provisional_name = nil
            dependency.plugin = plugin
          else
            dependency = entry.dependencies.where(
                                requirements: target[1],
                                provisional_name: nil,
                                plugin: plugin).first_or_initialize
          end
        else
          # 登録されていないgemの場合

          # 存在したpluginが後から削除された場合は、dependencyも自動的に削除されるが、
          # 再びこれを実行すると登録される。
          dependency = entry.dependencies.where(
                                requirements: target[1],
                                provisional_name: target[0]).first_or_initialize
        end
        dependency.save! if dependency.changed?
      end
    end
  end

  # Gemの情報を代入する
  def get_gem_uri
    gem_info = Gems.info(name)
    if gem_info.is_a?(Hash)
      path = gem_info['source_code_uri'].presence || gem_info['homepage_uri']
      self.source_code_uri = add_trailing_slash(path) if path.present?
      self.homepage_uri = gem_info['homepage_uri']
      # rubygemであるフラグを付ける
    else
      # rubygemに登録されていないplugin処理
    end
  end

  private

    # trailing slashを追加する
    def add_trailing_slash(path)
      # TODO: trailing slashを常に付ける方法が分からない
      path += '/' if path && path.last != '/'
      path
    end

# コールバック

  # def destroy_relatitons
  #   #gemの関連するもの削除する
  #   if dependency.present?
  #     dependency.destroy
  #   end
  #   if project_versions.present?
  #     project_versions.destroy_all
  #   end
  #   return true
  # end

  # 新規gem作成ログ
  def create_created_table_log
    CronLog.success_table(self.class.to_s.underscore, name, :create)
  end

  # 更新ログ
  def create_updated_table_log
    CronLog.success_table(self.class.to_s.underscore, name, :update)
  end

  # 削除ログ
  def create_destroyed_table_log
    CronLog.success_table(self.class.to_s.underscore, name, :delete)
  end


end
