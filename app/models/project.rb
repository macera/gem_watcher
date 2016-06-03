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
  has_many :plugins, dependent: :destroy

  def self.update_all
    Project.all.each do |project|
      project.plugins.destroy_all
      project.create_plugin_list
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

    # Gemfile.lockが存在しない場合、Gemfile.lockを作成する
    unless has_gemfile_lock?
      Dir.chdir("#{path}/#{name}") do
        Bundler.with_clean_env do
          result, e, s = Open3.capture3("bundle install")
        end
      end
    end
  end

  # 新しいバージョンが入手可能なgem情報を取得し、pluginsテーブルに保存
  def create_plugin_list
    path = "#{Rails.root}/#{Settings.path.working_directory}/#{name}"
    Dir.chdir(path) do
      Bundler.with_clean_env do
        result, e, s = Open3.capture3("bundle exec bundle outdated")
        gem_lines = []
        result.each_line do |line|
          if line.start_with?('  *')
            create_plugin(line)
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

  # bundle outdatedの返却値を元にpluginを作成する
  def create_plugin(line)
    plugins.create(plugin_attributes(line))
  end

  # bundle outdatedの返却値を元にpluginのattributesを作成する
  def plugin_attributes(line)
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

end
