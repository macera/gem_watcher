class AddGitlabCreatedAtAndGitlabUpdatedAtToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :gitlab_created_at, :datetime
    add_column :projects, :gitlab_updated_at, :datetime
  end
end
