class ChangePatchVersionOfProjectVersions < ActiveRecord::Migration[5.0]
  def up
    change_column :project_versions, :patch_version, 'integer USING CAST(patch_version AS integer)'
  end

  def down
    change_column :project_versions, :patch_version, :string
  end
end
