class CreateVulnerableEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :vulnerable_entries do |t|
      t.references :entry, foreign_key: true
      t.references :security_advisory, foreign_key: true

      t.timestamps
    end
  end
end
