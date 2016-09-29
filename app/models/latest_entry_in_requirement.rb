# == Schema Information
#
# Table name: latest_entry_in_requirements
#
#  id            :integer          not null, primary key
#  dependency_id :integer
#  entry_id      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_latest_entry_in_requirements_on_dependency_id  (dependency_id)
#  index_latest_entry_in_requirements_on_entry_id       (entry_id)
#
# Foreign Keys
#
#  fk_rails_996cd7c0b4  (dependency_id => dependencies.id)
#  fk_rails_faee29db97  (entry_id => entries.id)
#

class LatestEntryInRequirement < ApplicationRecord
  belongs_to :dependency
  belongs_to :entry
end
