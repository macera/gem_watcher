class CreateProjectVersions < ActiveRecord::Migration
  def change
    create_table :project_versions do |t|
      t.string :name
      t.string :newest
      t.string :installed
      t.string :pre
      t.references :project, index: true, foreign_key: true
      t.references :plugin, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
