class PluginForm
  include ActiveModel::Model

  attr_accessor :name, :updated

  def search
  end

  def search_by_project(project)
    scoped = project.project_versions
    scoped = scoped.newest_versions    if updated == '1'
    scoped = scoped.updated_versions   if updated == '2'
    scoped = scoped.joins(:plugin).where(['plugins.name like ?', name + '%']) if name.present?
    scoped
  end

end