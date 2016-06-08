# == Schema Information
#
# Table name: project_versions
#
#  id         :integer          not null, primary key
#  newest     :string
#  installed  :string
#  pre        :string
#  project_id :integer
#  plugin_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  requested  :string
#
# Indexes
#
#  index_project_versions_on_plugin_id   (plugin_id)
#  index_project_versions_on_project_id  (project_id)
#

class ProjectVersion < ActiveRecord::Base
  belongs_to :project
  belongs_to :plugin

  #scope :production, -> { where(group_type: nil) }
  scope :newest_versions, -> { where.not(newest: nil) }
  scope :updated_versions, -> { where(newest: nil) }
end
