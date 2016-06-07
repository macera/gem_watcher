class RemoveProjectFromPlugins < ActiveRecord::Migration
  def change
    remove_reference :plugins, :project, index: true, foreign_key: true
  end
end
