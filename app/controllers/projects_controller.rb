class ProjectsController < ApplicationController
  before_action :set_project, only: :show
  def index
    @projects = Project.all.page(params[:page])
  end

  def show
    form_values = params[:plugin_form] ? params[:plugin_form] : { updated: '1' }
    @form = PluginForm.new(form_values)
    @plugins = @form.search_by_project(@project)
  end

  private
  def set_project
    @project = Project.find(params[:id])
  end

end
