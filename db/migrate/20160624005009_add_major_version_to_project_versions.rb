class AddMajorVersionToProjectVersions < ActiveRecord::Migration
  def change
    add_column :project_versions, :major_version, :integer
  end
end
