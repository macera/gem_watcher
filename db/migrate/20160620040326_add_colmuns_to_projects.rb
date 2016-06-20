class AddColmunsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :web_url, :string
    add_column :projects, :description, :text
  end
end
