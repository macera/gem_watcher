class AddSourceCodeUriToPlugins < ActiveRecord::Migration
  def change
    add_column :plugins, :source_code_uri, :string
  end
end
