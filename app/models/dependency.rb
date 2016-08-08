# == Schema Information
#
# Table name: dependencies
#
#  id               :integer          not null, primary key
#  requirements     :string
#  provisional_name :string
#  plugin_id        :integer
#  entry_id         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_dependencies_on_entry_id   (entry_id)
#  index_dependencies_on_plugin_id  (plugin_id)
#
# Foreign Keys
#
#  fk_rails_036d07b9a2  (entry_id => entries.id)
#  fk_rails_b2e3a2e6a1  (plugin_id => plugins.id)
#

class Dependency < ApplicationRecord
  belongs_to :entry
  belongs_to :plugin

  after_create  :create_created_table_log
  #after_destroy :create_destroyed_table_log

  # 依存関係作成ログ
  def create_created_table_log
    plugin_name = plugin ? plugin.name : provisional_name
    CronLog.success_table(self.class.to_s.underscore, "#{entry.title}のDependencies(#{plugin_name})", :create)
  end

  # 削除ログ
  # def create_destroyed_table_log
  #   CronLog.success_table(self.class.to_s.underscore, "#{entry.title}のDependencies(#{plugin.name})", :delete)
  # end

end
