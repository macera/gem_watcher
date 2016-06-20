# -*- coding: utf-8 -*-
# == Schema Information
#
# Table name: projects
#
#  id               :integer          not null, primary key
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  gitlab_id        :integer          default(0), not null
#  http_url_to_repo :string           default(""), not null
#  ssh_url_to_repo  :string           default(""), not null
#  commit_id        :string
#  gemfile_content  :text
#

require "open3"

class Project < ActiveRecord::Base
  has_many :project_versions, dependent: :destroy
  has_many :plugins, through: :project_versions

  # project plugin project_version 更新
  def self.update_projects
    Project.all.each do |project|
      if project.updated_gemfile?
        project.update_gemfile               # git pull
        project.generate_gemfile_lock        # bundle install
        project.update_plugins_and_versions  # bundle list
        project.update_versions              # bundle outdated
      end
    end
  end

  # GitLabで新しく追加されたプロジェクトを管理下に追加
  def self.add_projects(option={})
    projects = gitlab_projects
    projects.sort_by! {|p| p.id } if option[:sort]
    projects.each do |project|
      result = Project.find_by(gitlab_id: project.id)
      unless result
        model = Project.new(
          name: project.name,
          gitlab_id: project.id,
          http_url_to_repo: project.http_url_to_repo,
          ssh_url_to_repo:  project.ssh_url_to_repo
        )
        has_gemfile = model.has_gemfile_in_remote?
        model.gemfile_content = model.newest_gemfile if has_gemfile
        model.commit_id = model.gitlab_commit_id
        model.save
        model.generate_project_files        # git clone
        if has_gemfile
          model.generate_gemfile_lock       # bundle install
          model.create_plugins_and_versions # bundle list
          model.update_versions             # bundle outdated
        end
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

    # git clone コマンド
  # projectのディレクトリを作成
  def generate_project_files
    path = "#{Rails.root}/#{Settings.path.working_directory}"
    Dir.chdir(path) do
      run("git clone #{ssh_url_to_repo}")
    end
  end

  # git pull コマンド
  # リポジトリ更新(Gemfileを更新するため)
  def update_gemfile
    Dir.chdir("#{Rails.root}/#{Settings.path.working_directory}/#{name}") do
      run("git pull origin master")
    end
    self.update(gemfile_content: newest_gemfile, commit_id: Gitlab.commits(gitlab_id).first.id)
  end

  # bundle install コマンド
  # Gemfile.lockを作成する(productionのみ取り出すため)
  def generate_gemfile_lock
    Dir.chdir("#{Rails.root}/#{Settings.path.working_directory}/#{name}") do
      Bundler.with_clean_env do
        run("bundle install --without development test")
      end
    end
  end

  # bundle list コマンド
  # 新しいgemが追加されたら、project_version追加(pluginがなければ作成)
  def create_plugins_and_versions
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result = run("bundle list")
        result.each_line do |line|
          if line.start_with?('  * ')
            value = line.scan(/\s\s\*\s(\S+)\s\((.+)\)/).flatten
            plugin = Plugin.find_or_create_by(name: value[0]) do |p|
              p.get_gem_uri
            end
            project_versions.create(installed: value[1], plugin_id: plugin.id)
          end
        end
      end
    end
  end

  # bundle list コマンド
  # 新しいgemが追加されたら、project_version追加(pluginがなければ作成)
  # 既存のgemが削除されたら、project_version削除(versionが1件もなくなればplugin削除)
  def update_plugins_and_versions
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result = run("bundle list")
        names = []
        # 新規gemがあれば追加する
        result.each_line do |line|
          if line.start_with?('  * ')
            value = line.scan(/\s\s\*\s(\S+)\s\((.+)\)/).flatten
            version = project_versions.joins(:plugin).where('plugins.name' => value[0]).first
            if version
              # installedのみ更新、他は初期化(update_versionsで取得し直す)
              version.update(installed: value[1], newest: nil, requested: nil)
            else
              plugin = Plugin.find_or_create_by(name: value[0]) do |p|
                p.get_gem_uri
              end
              project_versions.create(installed: value[1], plugin_id: plugin.id)
            end
            names << value[0]
          end
        end
        # 削除すべきgemがあれば削除する
        project_versions.each do |version|
          unless names.include?(version.plugin.name)
            target_gem = version.plugin
            version.destroy
            # versionが1件もないpluginの場合削する
            if target_gem.project_versions.blank?
              target_gem.destroy
            end
          end
        end

      end
    end
  end

  # bundle outdated コマンド
  # 新しいバージョンが入手可能なgem情報を取得し、project_versionテーブルを更新
  def update_versions
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result = run("bundle outdated")
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
            project_version.update(attr)
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
  rescue => e
    logger.error "エラーが発生しました: #{e}"
    # ひとまず自身のファイル内容を返す
    return gemfile_content
  end

  private

  # gitlabのプロジェクト一覧を返す
  def self.gitlab_projects
    Gitlab.projects
  rescue => e
    logger.error "エラーが発生しました: #{e}"
    return []
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

  # commit idを返却する
  def gitlab_commit_id
    Gitlab.commits(gitlab_id).first.id
  rescue => e
    logger.error "エラーが発生しました: #{e}"
    return nil
  end

  # ルートディレクトリ・ファイル一覧を返す API
  def root_dirs
    Gitlab.tree(gitlab_id)
  rescue => e
    logger.error "エラーが発生しました: #{e}"
    return []
  end

  # コマンドを実行する
  def run(command)
    result, e, s = Open3.capture3(command)
    return result
  end

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
