# == Schema Information
#
# Table name: plugins
#
#  id         :integer          not null, primary key
#  name       :string
#  newest     :string
#  installed  :string
#  requested  :string
#  pre        :string
#  project_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_type :string
#
# Indexes
#
#  index_plugins_on_project_id  (project_id)
#

class Plugin < ActiveRecord::Base
  belongs_to :project

  scope :production, -> { where(group_type: nil) }

end
