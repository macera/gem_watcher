class AddRequestedToProjectVersions < ActiveRecord::Migration
  def change
    add_column :project_versions, :requested, :string
  end
end
