class AddCommitIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :commit_id, :string
  end
end
