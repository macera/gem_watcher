class AddColumnsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :http_url_to_repo, :string, null: false, default: ''
    add_column :projects, :ssh_url_to_repo, :string, null: false, default: ''
  end
end
