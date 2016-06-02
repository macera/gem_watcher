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
#
# Indexes
#
#  index_plugins_on_project_id  (project_id)
#

class Plugin < ActiveRecord::Base
  belongs_to :project
end
