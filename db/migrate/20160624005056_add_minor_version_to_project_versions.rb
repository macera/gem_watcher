class AddMinorVersionToProjectVersions < ActiveRecord::Migration
  def change
    add_column :project_versions, :minor_version, :integer
  end
end
