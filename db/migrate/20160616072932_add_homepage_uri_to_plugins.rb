class AddHomepageUriToPlugins < ActiveRecord::Migration
  def change
    add_column :plugins, :homepage_uri, :string
  end
end
