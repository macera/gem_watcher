class AddGroupTypeToPlugins < ActiveRecord::Migration
  def change
    add_column :plugins, :group_type, :string
  end
end
