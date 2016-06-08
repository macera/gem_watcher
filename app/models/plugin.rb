# == Schema Information
#
# Table name: plugins
#
#  id              :integer          not null, primary key
#  name            :string
#  newest          :string
#  installed       :string
#  requested       :string
#  pre             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  group_type      :string
#  source_code_uri :string
#

class Plugin < ActiveRecord::Base
  has_many :project_versions
  has_many :projects, through: :project_versions

  # before_create :get_source_code_uri

  #scope :production, -> { joins(:project_versions).merge(ProjectVersion.production).uniq }

  def get_source_code_uri
    gem_info = Gems.info(name)
    if gem_info.is_a?(Hash)
      path = gem_info['source_code_uri'].presence || gem_info['homepage_uri']
      # TODO: trailing slashを常に付ける方法が分からない
      path += '/' if path && path.last != '/'
      self.source_code_uri = path
    end
  end

end
