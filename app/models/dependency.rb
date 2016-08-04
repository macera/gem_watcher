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
end
