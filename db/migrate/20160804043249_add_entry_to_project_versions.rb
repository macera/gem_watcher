class AddEntryToProjectVersions < ActiveRecord::Migration[5.0]
  def change
    add_reference(:project_versions, :entry, foreign_key: true, index: true)
  end
end
