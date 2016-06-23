class CreateCronLogs < ActiveRecord::Migration
  def change
    create_table :cron_logs do |t|
      t.string :table_name
      t.text :content
      t.integer :state

      t.timestamps null: false
    end
  end
end
