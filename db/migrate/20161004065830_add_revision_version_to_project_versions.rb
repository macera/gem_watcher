class AddRevisionVersionToProjectVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :project_versions, :revision_version, :string
  end
end
