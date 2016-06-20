class ProjectsController < ApplicationController

  before_action :set_project, only: [:show, :edit, :update]
  before_action :check_updatable, only: [:edit, :update]

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

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to @project, notice: '正しく登録されました。'
    else
      render action: :new
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: '正しく更新されました。'
    else
      render action: :edit
    end
  end

  private
  def set_project
    @project = Project.find(params[:id])
  end

  # 更新可能なプロジェクトか確認する
  def check_updatable

  end

  def project_params
    params.require(:project).permit(
      :name, :description, :http_url_to_repo, :ssh_url_to_repo, :web_url
    )
  end

end
