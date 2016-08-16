class CreateSecurityAdvisories < ActiveRecord::Migration[5.0]
  def change
    create_table :security_advisories do |t|

      t.references :plugin, foreign_key: true
      t.string :framework
      t.string :cve
      t.integer :osvdb
      t.text :description
      t.string :cvss_v2
      t.string :cvss_v3
      t.date :date
      t.string :unaffected_versions
      t.string :patched_versions
      t.string :path

      t.timestamps
    end
  end
end
