class AddRevisionVersionToEntries < ActiveRecord::Migration[5.0]
  def change
    add_column :entries, :revision_version, :string
  end
end
