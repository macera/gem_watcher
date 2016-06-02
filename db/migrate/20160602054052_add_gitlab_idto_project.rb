class AddGitlabIdtoProject < ActiveRecord::Migration
  def change
    add_column :projects, :gitlab_id, :integer, null: false, default: 0
  end
end
