class RemoveColumnsToProjectVersions < ActiveRecord::Migration
  def change
    remove_column :project_versions, :group_type, :string
    remove_column :project_versions, :name, :string
  end
end
