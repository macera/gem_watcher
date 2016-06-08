class RemoveColumnsToPlugins < ActiveRecord::Migration
  def change
    remove_column :plugins, :group_type, :string
    remove_column :plugins, :installed, :string
    remove_column :plugins, :requested, :string
  end
end
