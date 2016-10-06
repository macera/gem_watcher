class ChangePatchVersionOfEntries < ActiveRecord::Migration[5.0]
  def up
    change_column :entries, :patch_version, 'integer USING CAST(patch_version AS integer)'
  end

  def down
    change_column :entries, :patch_version, :string
  end
end
