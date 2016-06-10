# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# GitLabからprojectを取得し、projectsテーブルを作成する
Project.destroy_all
Plugin.destroy_all
projects = Gitlab.projects.sort_by {|p| p.id }
projects.each do |project|
  #unless Project.find_by(gitlab_id: project.gitlab_id)
    model = Project.new(
      name: project.name,
      gitlab_id: project.id,
      http_url_to_repo: project.http_url_to_repo,
      ssh_url_to_repo: project.ssh_url_to_repo,
      commit_id: Gitlab.commits(project.id).first.id
    )
    model.save
    model.generate_project_files # git clone
    if model.has_gemfile?
      model.generate_gemfile_lock  # bundle install

      model.create_plugins_and_versions # bundle list
      model.update_for_outdated_version # bundle outdated
    end
  #end
end
