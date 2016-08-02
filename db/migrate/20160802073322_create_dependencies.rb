class CreateDependencies < ActiveRecord::Migration[5.0]
  def change
    create_table :dependencies do |t|
      t.string :requirements
      t.references :plugin, foreign_key: true
      t.references :entry, foreign_key: true

      t.timestamps
    end
  end
end
