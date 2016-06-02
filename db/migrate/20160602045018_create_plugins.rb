class CreatePlugins < ActiveRecord::Migration
  def change
    create_table :plugins do |t|
      t.string :name
      t.string :newest
      t.string :installed
      t.string :requested
      t.string :pre
      t.references :project, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
