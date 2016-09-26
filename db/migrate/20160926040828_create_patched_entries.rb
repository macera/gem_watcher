class CreatePatchedEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :patched_entries do |t|
      t.references :entry, foreign_key: true
      t.references :security_advisory, foreign_key: true

      t.timestamps
    end
  end
end
