class AddGemfileContentToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :gemfile_content, :text
  end
end
