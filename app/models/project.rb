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

class Project < ActiveRecord::Base
  has_many :plugins

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

  # projectを'git clone'する
  def clone
    Dir.chdir("#{Rails.root}/#{Settings.path.working_directory}")
    command = "git clone #{ssh_url_to_repo}"
    system(command)
    #Dir.chdir("./#{name}") # cd project
    Dir.chdir(Rails.root)
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

end
