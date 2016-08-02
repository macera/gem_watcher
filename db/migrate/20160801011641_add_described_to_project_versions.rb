class AddDescribedToProjectVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :project_versions, :described, :boolean
  end
end
