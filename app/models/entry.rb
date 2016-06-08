# == Schema Information
#
# Table name: entries
#
#  id         :integer          not null, primary key
#  title      :string
#  published  :datetime
#  content    :text
#  url        :string
#  author     :string
#  plugin_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_entries_on_plugin_id  (plugin_id)
#

class Entry < ActiveRecord::Base
  belongs_to :plugin

end
