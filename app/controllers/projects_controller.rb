class ProjectsController < ApplicationController
  before_action :set_project, only: :show
  def index
    @search = Project.ransack(params[:q])
    # TODO: 新しいプロジェクト順に並べ替える
    @projects = @search.result.page(params[:page])
  end

  def show
    # TODO: ransackに変えたい(ransackのradioボタン検索が難しい)
    form_values = params[:plugin_form] ? params[:plugin_form] : { updated: '1' }
    @form = PluginForm.new(form_values)
    @plugins = @form.search_by_project(@project)
  end

  private
  def set_project
    @project = Project.find(params[:id])
  end

end
