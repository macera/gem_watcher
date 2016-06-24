class AddPatchVersionToProjectVersions < ActiveRecord::Migration
  def change
    add_column :project_versions, :patch_version, :string
  end
end
