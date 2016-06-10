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
  def self.update_all
    Project.all.each do |project|
      project.update_project_files         # create or destroy plugin, project_version
      project.update_for_outdated_version  # update project_version
    end
  end

  # GitLabで新しく追加されたプロジェクトを管理下に追加
  def self.add_projects
    Gitlab.projects.each do |project|
      result = Project.find_by(gitlab_id: project.id)
      unless result
        model = Project.new(
          name: project.name,
          gitlab_id: project.id,
          http_url_to_repo: project.http_url_to_repo,
          ssh_url_to_repo:  project.ssh_url_to_repo,
          commit_id: Gitlab.commits(project.id).first.id
        )
        model.gemfile_content = model.newest_gemfile if model.has_gemfile?
        model.save
        model.generate_project_files        # git clone
        if model.has_gemfile?
          model.generate_gemfile_lock       # bundle install
          model.create_plugins_and_versions # bundle list
          model.update_for_outdated_version # bundle outdated
        end
      end
    end
  end

  # Gemfileがあるプロジェクトか調べる
  def has_gemfile?
    exist_file?('Gemfile')
  end

  # Gemfile.lockがあるプロジェクトか調べる
  def has_gemfile_lock?
    exist_file?('Gemfile.lock')
  end

  # Gemfileの内容を返す
  def newest_gemfile
    Gitlab.file_contents(gitlab_id, 'Gemfile').encode(Encoding::Windows_31J, Encoding::UTF_8, undef: :replace)
  end

  # Gemfileが変更されているか
  def updated_gemfile?
    has_gemfile? && gemfile_content != newest_gemfile
  end

  # projectのディレクトリを作成
  def generate_project_files
    path = "#{Rails.root}/#{Settings.path.working_directory}"
    Dir.chdir(path) do
      system("git clone #{ssh_url_to_repo}")
    end
  end

  # リポジトリ更新(Gemfileを更新するため)
  def update_project_files
    if updated_gemfile?
      Dir.chdir("#{Rails.root}/#{Settings.path.working_directory}/#{name}") do
        system("git pull origin master")
      end
      self.update(gemfile_content: newest_gemfile, commit_id: Gitlab.commits(gitlab_id).first.id)
      # project_versionとpluginテーブルを更新する
      self.update_plugins_and_versions
    end
  end

  # Gemfile.lockを作成する(productionのみ取り出すため)
  def generate_gemfile_lock
    Dir.chdir("#{Rails.root}/#{Settings.path.working_directory}/#{name}") do
      Bundler.with_clean_env do
        result, e, s = Open3.capture3("bundle install --without development test")
      end
    end
  end

  # 新しいgemが追加されたら、project_version追加(pluginがなければ作成)
  def create_plugins_and_versions
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result, e, s = Open3.capture3("bundle exec bundle list")
        result.each_line do |line|
          if line.start_with?('  * ')
            value = line.scan(/\s\s\*\s(\S+)\s\((.+)\)/).flatten
            plugin = Plugin.find_or_create_by(name: value[0]) do |p|
              p.get_source_code_uri
            end
            project_versions.create(installed: value[1], plugin_id: plugin.id)
          end
        end
      end
    end
  end

  # 新しいgemが追加されたら、project_version追加(pluginがなければ作成)
  # 既存のgemが削除されたら、project_version削除
  def update_plugins_and_versions
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result, e, s = Open3.capture3("bundle exec bundle list")
        names = []
        # 新規gemがあれば追加する
        result.each_line do |line|
          if line.start_with?('  * ')
            value = line.scan(/\s\s\*\s(\S+)\s\((.+)\)/).flatten
            version = project_versions.joins(:plugin).where('plugins.name' => value[0]).first
            unless version
              plugin = Plugin.find_or_create_by(name: value[0]) do |p|
                p.get_source_code_uri
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

  # 新しいバージョンが入手可能なgem情報を取得し、project_versionテーブルを更新
  def update_for_outdated_version
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result, e, s = Open3.capture3("bundle exec bundle outdated")
        result.each_line do |line|
          if line.start_with?('  *')
            update_project_version(line)
          end
        end
      end
    end
  end

  # 指定のファイルを取得
  # def get_file(file_path)
  #   Gitlab.get_file(gitlab_id, file_path, 'master')
  # end

  private

  # ファイルの存在チェック(トップディレクトリのみ)
  def exist_file?(file)
    Gitlab.tree(gitlab_id).each do |obj|
      if obj.name == file
        return true
      end
    end
    return false
  end

  def update_project_version(line)
    attribute = project_version_attributes(line)
    project_version = project_versions.joins(:plugin).where('plugins.name' => attribute['name']).first
    if project_version
      # development, testのみのgemは除く
      return unless production?(line)
      attribute.delete('name')
      project_version.update(attribute)
    end
  end

  # bundle outdatedの返却値を元にproject_versionのattributesを作成する
  def project_version_attributes(line)
    plugin_name = line.scan(/\s\s\*\s(\S+)\s/).flatten[0]
    attr = { 'name' => plugin_name }
    versions = line.scan(/\((\S+\s.+)\)/).flatten[0].split(', ')
    versions.each do |v|
      tmp = v.scan(/(\S+)\s(.+)/).flatten
      state = tmp[0]
      version = tmp[1]
      attr.merge!({ state => version })
    end
    attr
  end

  # prodution環境で使うgemか調べる
  def production?(line)
    group_type = line.scan(/in\sgroups?\s"(\S+)"/).flatten[0]
    if group_type == nil or
      group_type == 'default' or
      (group_type && group_type.include?('production'))
      true
    end
  end

end
