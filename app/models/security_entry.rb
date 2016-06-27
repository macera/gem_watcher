# == Schema Information
#
# Table name: security_entries
#
#  id         :integer          not null, primary key
#  title      :string
#  published  :datetime
#  content    :text
#  url        :string
#  author     :string
#  genre      :integer
#  plugin_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_security_entries_on_plugin_id  (plugin_id)
#

class SecurityEntry < ActiveRecord::Base
  belongs_to :plugin

  after_create  :create_created_table_log

  # 新規gem作成ログ
  def create_created_table_log
    CronLog.success_table(self.class.to_s.underscore, "#{plugin.name}: #{title}", :create)
  end
end
