class AddPatchVersionToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :patch_version, :string
  end
end
