class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.string :title
      t.datetime :published
      t.text :content
      t.string :url
      t.string :author
      t.references :plugin, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
