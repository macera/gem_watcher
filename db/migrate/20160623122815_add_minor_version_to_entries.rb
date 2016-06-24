class AddMinorVersionToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :minor_version, :integer
  end
end
