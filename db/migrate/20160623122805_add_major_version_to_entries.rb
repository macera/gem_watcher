class AddMajorVersionToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :major_version, :integer
  end
end
