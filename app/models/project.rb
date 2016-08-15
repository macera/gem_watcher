# -*- coding: utf-8 -*-
# == Schema Information
#
# Table name: projects
#
#  id                :integer          not null, primary key
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  gitlab_id         :integer
#  http_url_to_repo  :string           default(""), not null
#  ssh_url_to_repo   :string           default(""), not null
#  commit_id         :string
#  gemfile_content   :text
#  web_url           :string
#  description       :text
#  gitlab_created_at :datetime
#  gitlab_updated_at :datetime
#

require "open3"

class Project < ActiveRecord::Base
  include DisplayVersion

  has_many :plugins, through: :project_versions
  has_many :project_versions, dependent: :destroy

  accepts_nested_attributes_for :project_versions, allow_destroy: true,
                                 reject_if: :all_blank

  validates :name, presence: true
  validates :name, length: { maximum: 50 }, allow_blank: true
  validates :name, format: { with: /\A[a-z0-9_-]+\z/i }, allow_blank: true


  #validate :exist_project

  # validates :description, length: { maximum: 500 }, allow_blank: true

  # validates :web_url, presence: true
  # validates :web_url, length: { maximum: 200 }, allow_blank: true
  # validates :web_url, format: /\A#{URI::regexp(%w(http https))}\z/, allow_blank: true

  # validates :http_url_to_repo, presence: true
  # validates :http_url_to_repo, length: { maximum: 200 }, allow_blank: true
  # validates :http_url_to_repo, format: /\A#{URI::regexp(%w(http https))}\z/, allow_blank: true

  # # TODO: ちゃんとした正規表現に修正したい
  # validates :ssh_url_to_repo, presence: true
  # validates :ssh_url_to_repo, length: { maximum: 200 }, allow_blank: true
  # validates :ssh_url_to_repo, format: /\Agit\@\S+\/\S+\.git\z/, allow_blank: true

  after_create :create_created_table_log
  after_update :create_updated_table_log

  # project plugin project_version 更新
  def self.update_projects
    Project.all.each do |project|
      begin
        if project.updated_gemfile?
          project.update_gemfile               # git pull
          project.generate_gemfile_lock        # bundle install
          project.update_plugins_and_versions  # bundle list
        end
        if project.has_gemfile_in_remote?
          project.update_versions                 # bundle outdated
        end
      rescue Gitlab::Error::Forbidden => e
        CronLog.error_create(
          table_name: self.class.to_s.underscore,
          content: "メソッド:add_projects 詳細:#{e}"
        )
      rescue StandardError => e
        CronLog.error_create(
          table_name: self.class.to_s.underscore,
          content: "メソッド:update_projects 詳細:#{e}"
        )
      end
    end
  end

  # GitLabで新しく追加されたプロジェクトを管理下に追加
  def self.add_projects(option={})
    projects = gitlab_projects
    projects.sort_by! {|p| p.id } if option[:sort]
    projects.each do |project|
      begin
        result = Project.find_by(gitlab_id: project.id)
        unless result
          model = Project.new(
            name:              project.name,
            gitlab_id:         project.id,
            http_url_to_repo:  project.http_url_to_repo,
            ssh_url_to_repo:   project.ssh_url_to_repo,
            web_url:           project.web_url,
            description:       project.description,
            gitlab_created_at: project.created_at,
            gitlab_updated_at: project.last_activity_at
          )
          has_gemfile = model.has_gemfile_in_remote?
          model.gemfile_content = model.newest_gemfile if has_gemfile
          model.commit_id = model.gitlab_commit_id
          a = model.save

          model.generate_project_files        # git clone(mkdir + copy Gemfile)
          if has_gemfile
            model.generate_gemfile_lock       # bundle install
            model.create_plugins_and_versions # bundle list
            model.update_versions             # bundle outdated
          end
        end
      rescue Gitlab::Error::Forbidden => e
        CronLog.error_create(
          table_name: self.class.to_s.underscore,
          content: "メソッド:add_projects 詳細:#{e}"
        )
      rescue => e
        CronLog.error_create(
          table_name: self.class.to_s.underscore,
          content: "メソッド:add_projects 詳細:#{e}"
        )
      end
    end
  end

  # 許可するカラムの名前をオーバーライドする
  def self.ransackable_attributes(auth_object = nil)
    %w(id name)
  end

  # 許可する関連の配列をオーバーライドする
  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

  def self.ransackable_scopes(auth_object = nil)
    %i[]
  end

  # Gemfileがあるプロジェクトか調べる(ローカル)
  # def has_gemfile?
  #   File.exist?("#{Rails.root}/#{Settings.path.working_directory}/#{name}/Gemfile")
  # end

  # Gemfileがあるプロジェクトか調べる(リモート)
  def has_gemfile_in_remote?
    exist_file?('Gemfile')
  end

  def has_gemfile_lock_in_remote?
    exist_file?('Gemfile.lock')
  end

  # projectのディレクトリを作成
  def generate_project_files
    path = "#{Rails.root}/#{Settings.path.working_directory}"
    Dir.chdir(path) do
      # TODO: gitを使わなくて済むように修正する
      run("mkdir #{name}") unless Dir.exist?("name")
    end
    Dir.chdir("#{path}/#{name}") do
      if has_gemfile_in_remote?
        gemfile = File.open('Gemfile', "w") do |file|
          file.print(newest_gemfile)
        end
        # engine gemをコメントアウトする
        comment_gems_with_path_option
      end
      if has_gemfile_lock_in_remote?
        File.open('Gemfile.lock', "w") do |file|
          file.print(newest_gemfile_lock)
        end
      end
      #run("git clone #{ssh_url_to_repo}")
    end
  end

  # Gemfile、Gemfile.lockを更新する(git pullは使わない)
  def update_gemfile
    Dir.chdir("#{Rails.root}/#{Settings.path.working_directory}/#{name}") do
      if has_gemfile_in_remote?
        gemfile = File.open('Gemfile', "w+") do |file|
          file.print(newest_gemfile)
        end
        # engine gemをコメントアウトする
        comment_gems_with_path_option
      end
      if has_gemfile_lock_in_remote?
        File.open('Gemfile.lock', "w") do |file|
          file.print(newest_gemfile_lock)
        end
      end
      #run("git pull origin master")
    end
    self.update(
      gemfile_content: newest_gemfile,
      commit_id:       gitlab_commit_id,
      gitlab_updated_at: get_gitlab_updated_at
    )
  end

  # bundle install コマンド
  # Gemfile.lockを作成する(productionのみ取り出すため)
  def generate_gemfile_lock
    Dir.chdir("#{Rails.root}/#{Settings.path.working_directory}/#{name}") do
      Bundler.with_clean_env do
        result = run("bundle install --path vendor/bundle --without development test")
        # エラーチェック
        unless result.include? 'Bundle complete!'
          message = ''
          if result =~ /An\serror\soccurred\swhile\sinstalling/
            message = $'
          end
          raise "bundle install でエラーが発生しました。=> #{message}"
        end
      end
    end
  end

  # bundle list コマンド
  # 新しいgemが追加されたら、project_version追加(pluginがなければ作成)
  def create_plugins_and_versions
    gemfile_gems = gemfile_list
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do

        result = run("bundle list")
        # エラーチェック
        if result.include? "Could not find"
          raise "bundle list でエラーが発生しました。=> #{result}"
        end
        result.each_line do |line|
          if line.start_with?('  * ')
            value = line.scan(/\s\s\*\s(\S+)\s\((.+)\)/).flatten

            new_plugin = Plugin.find_or_initialize_by(name: value[0])
            # gem情報更新
            new_plugin.get_gem_uri# if valid_plugin_format?
            # p new_plugin.name
            new_plugin.save! if new_plugin.changed?

            Entry.update_all(new_plugin)
            version = split_version(value[1])
            entry = new_plugin.entries.where(major_version: version[0],
                                             minor_version: version[1],
                                             patch_version: version[2]
            ).first

            project_versions.create!(installed: value[1],
                                     plugin:    new_plugin,
                                     entry:     entry,
                                     described: gemfile_gems.include?(value[0])
            )
          end
        end
      end
    end
  end

  # bundle list コマンド
  # 新しいgemが追加されたら、project_version追加(pluginがなければ作成)
  # 既存のgemが削除されたら、project_version削除(versionが1件もなくなればplugin削除)
  def update_plugins_and_versions
    gemfile_gems = gemfile_list
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result = run("bundle list")
        # エラーチェック
        if result.include? "Could not find"
          raise "bundle list でエラーが発生しました。=> #{result}"
        end
        names = []
        # 新規gemがあれば追加する
        result.each_line do |line|
          if line.start_with?('  * ')
            value = line.scan(/\s\s\*\s(\S+)\s\((.+)\)/).flatten

            version = project_versions.joins(:plugin).where('plugins.name' => value[0]).first
            if version
              # installedのみ更新、他は初期化(update_versionsで取得し直す)
              version.update(installed: value[1],
                             newest:    nil,
                             requested: nil,
                             described: gemfile_gems.include?(value[0])
              )
            else
              new_plugin = Plugin.find_or_initialize_by(name: value[0])
              # gem情報更新
              new_plugin.get_gem_uri# if valid_plugin_format?
              new_plugin.save! if new_plugin.changed?

              # TODO: この時、plugin.entriesを作成
              Entry.update_all(new_plugin)
              # TODO: value[1]のversionのentryをproject_versionに登録する
              version = split_version(value[1])
              entry = new_plugin.entries.where(major_version: version[0],
                                               minor_version: version[1],
                                               patch_version: version[2]
              ).first

              project_versions.create!(installed: value[1],
                                       plugin:    new_plugin,
                                       entry:     entry,
                                       described: gemfile_gems.include?(value[0])
              )
            end
            names << value[0]
          end
        end
        # 削除すべきgemがあれば削除する
        project_versions.each do |version|
          unless names.include?(version.plugin.name)
            #target_gem = version.plugin
            version.destroy
            # versionが1件もないpluginの場合削する
            # if target_gem.project_versions.blank?
            #   target_gem.destroy
            # end
          end
        end

      end
    end
  end

  # bundle outdated コマンド
  # 新しいバージョンが入手可能なgem情報を取得し、project_versionテーブルを更新
  def update_versions
    gemfile_gems = gemfile_list
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result = run("bundle outdated")
        # エラーチェック
        if result.include? "Could not find"
          raise "bundle outdated でエラーが発生しました。=> #{result}"
        end
        result.each_line do |line|
          next unless line.start_with?('  *')
          plugin_name = line.scan(/\s\s\*\s(\S+)\s/).flatten[0]

          versions = line.scan(/\((\S+\s.+)\)/).flatten[0].split(', ')
          attr = {}
          versions.each do |v|
            tmp = v.scan(/(\S+)\s(.+)/).flatten
            state = tmp[0]
            version = tmp[1]
            attr.merge!({ state => version })
          end

          project_version = project_versions.joins(:plugin).where('plugins.name' => plugin_name).first
          if project_version
            # development, testのみのgemは除く
            #return unless production?(line)
            project_version.update!(attr)
          end
        end
      end
    end
  end

  # Gemfileが変更されているか(リモート)
  def updated_gemfile?
    has_gemfile_in_remote? && gemfile_content != newest_gemfile
  end

  # API
  # エラーログを取得する

  # Gemfileの内容を返す
  def newest_gemfile
    Gitlab.file_contents(gitlab_id, 'Gemfile').force_encoding("UTF-8")
    #.encode(Encoding::Windows_31J, Encoding::UTF_8, undef: :replace)
  end

  def newest_gemfile_lock
    Gitlab.file_contents(gitlab_id, 'Gemfile.lock').force_encoding("UTF-8")
  end

  # commit idを返却する
  def gitlab_commit_id
    Gitlab.commits(gitlab_id).first.id
  end

  # Gemfileに書かれているgem一覧を配列で返す
  def gemfile_list
    target_gems = []
    gemfile_content.each_line do |line|
      text = line.gsub(/(\t|\n)/, "") # タブ、改行を消す
      text =~ /#/
      text = text.gsub(/#{$'}/, "") # #コメント以降を削除する
      next if text == ""
      target = text.scan(/gem\s['|"](\S+)['|"]/).flatten[0]
      target_gems << target if target
    end
    target_gems
  end

  # Gemfile path:オプションのgemをコメントアウトする(engineなどは管理しないため)
  def comment_gems_with_path_option
    Tempfile.open('tmp_file') do |tf|
      IO.foreach('Gemfile') do |line|
        # TODO: 一旦git githubもエラー防ぐ為に外します
        if line =~ /gem\s['|"]\S+['|"].+(path|git|github):/
          line = line.gsub(/gem/, '#gem')
        end
        tf.write line
      end
      tf.close
      FileUtils.copy_file tf.path, 'Gemfile'
    end
  end

  def has_security_alert?
    project_versions.each do |version|
      return true if SecurityAdvisory.check_gem(version.plugin, version.installed).present?
    end
    return false
  end

  private

  # コールバック
  # 新規プロジェクト作成ログ
  def create_created_table_log
    CronLog.success_table(self.class.to_s.underscore, name, :create)
  end
  # プロジェクトの更新ログ
  def create_updated_table_log
    CronLog.success_table(self.class.to_s.underscore, name, :update)
  end

  # gitlabのプロジェクト一覧を返す
  def self.gitlab_projects
    Gitlab.projects
  end

  # ファイルの存在チェック(トップディレクトリのみ)
  def exist_file?(file)
    root_dirs.each do |obj|
      if obj.name == file
        return true
      end
    end
    return false
  end

  # ルートディレクトリ・ファイル一覧を返す API
  def root_dirs
    Gitlab.tree(gitlab_id)
  end

  # gitlabのlast_activity_atを取得する
  def get_gitlab_updated_at
    Gitlab.project(gitlab_id).last_activity_at
  end

  # コマンドを実行する
  def run(command)
    result, e, s = Open3.capture3(command)
    return result
  end

# バリデーション

  # prodution環境で使うgemか調べる
  # def production?(line)
  #   group_type = line.scan(/in\sgroups?\s"(\S+)"/).flatten[0]
  #   if group_type == nil or
  #     group_type == 'default' or
  #     (group_type && group_type.include?('production'))
  #     true
  #   end
  # end

end
