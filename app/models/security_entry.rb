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
end
