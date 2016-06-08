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
#
require "open3"

class Project < ActiveRecord::Base
  has_many :project_versions, dependent: :destroy
  has_many :plugins, through: :project_versions

  # gem情報更新
  def self.update_all
    Project.all.each do |project|
      #project.project_versions.destroy_all
      #project.create_project_version_list
      project.update_for_outdated_version
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
  def gemfile_content
    Gitlab.file_contents(gitlab_id, 'Gemfile')
  end

  # projectのディレクトリを作成
  def generate_project_files
    path = "#{Rails.root}/#{Settings.path.working_directory}"
    Dir.chdir(path) do
      system("git clone #{ssh_url_to_repo}")
    end
  end

  # Gemfile.lockを作成する
  def generate_gemfile_lock
    # Gemfile.lockが存在しない場合、Gemfile.lockを作成する
    #unless has_gemfile_lock?
      Dir.chdir("#{Rails.root}/#{Settings.path.working_directory}/#{name}") do
        Bundler.with_clean_env do
          result, e, s = Open3.capture3("bundle install --without development test")
        end
      end
    #end
  end

  # bundle listで所有するgem情報を取得しproject_versionテーブルに保存
  # pluginが存在しない場合、pluginも保存する
  def create_plugins_and_versions
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result, e, s = Open3.capture3("bundle exec bundle list")
        gem_lines = []
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

  # 新しいバージョンが入手可能なgem情報を取得し、project_versionテーブルを更新
  def update_for_outdated_version
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result, e, s = Open3.capture3("bundle exec bundle outdated")
        gem_lines = []
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

  # bundle outdatedの返却値を元にproject_versionを作成する
  # def create_project_version(line)
  #   project_versions.create(project_version_attributes(line))
  # end

  def update_project_version(line)
    attribute = project_version_attributes(line)
    project_version = project_versions.where(name: attribute['name']).first
    if project_version
      # development, testのみのgemは除く
      return unless production?(line)
      project_version.update(attribute)
    end
  end


  # bundle outdatedの返却値を元にproject_versionのattributesを作成する
  def project_version_attributes(line)
    # plugin_name = line.scan(/\s\s\*\s(\S+)\s/).flatten[0]
    # attr = { 'name' => plugin_name }
    attr = {}
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
