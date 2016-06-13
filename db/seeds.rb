# GitLabからprojectを取得し、projectsテーブルを作成する
Project.destroy_all
Plugin.destroy_all
Project.add_projects({ sort: true })
# projects = Gitlab.projects.sort_by {|p| p.id }
# projects.each do |project|
#   #unless Project.find_by(gitlab_id: project.gitlab_id)
#     model = Project.new(
#       name: project.name,
#       gitlab_id: project.id,
#       http_url_to_repo: project.http_url_to_repo,
#       ssh_url_to_repo: project.ssh_url_to_repo,
#       commit_id: Gitlab.commits(project.id).first.id
#     )
#     model.gemfile_content = model.newest_gemfile if model.has_gemfile?
#     model.save
#     model.generate_project_files # git clone
#     if model.has_gemfile?
#       model.generate_gemfile_lock  # bundle install

#       model.create_plugins_and_versions # bundle list
#       model.update_for_outdated_version # bundle outdated
#     end
#   #end
# end
