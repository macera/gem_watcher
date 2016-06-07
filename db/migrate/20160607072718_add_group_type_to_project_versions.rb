class AddGroupTypeToProjectVersions < ActiveRecord::Migration
  def change
    add_column :project_versions, :group_type, :string
  end
end
