class ChangeGitlabIdToProjects < ActiveRecord::Migration
  def up
   change_column :projects, :gitlab_id, :integer, default: nil, null: true
  end

  def down
   change_column :projects, :gitlab_id, :integer, default: 0, null: false
  end
end
