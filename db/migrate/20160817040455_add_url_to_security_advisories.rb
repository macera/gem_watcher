class AddUrlToSecurityAdvisories < ActiveRecord::Migration[5.0]
  def change
    add_column :security_advisories, :url, :string
  end
end
