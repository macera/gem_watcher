class CreateLatestEntryInRequirements < ActiveRecord::Migration[5.0]
  def change
    create_table :latest_entry_in_requirements do |t|
      t.references :dependency, foreign_key: true
      t.references :entry, foreign_key: true

      t.timestamps
    end
  end
end
