class ProjectsController < ApplicationController

  before_action :set_project, only: [:show, :edit, :update]
  before_action :check_updatable, only: [:edit, :update]

  # プロジェクト一覧画面
  def index
    @search = Project.order('gitlab_created_at desc').ransack(params[:q])
    # TODO: 新しいプロジェクト順に並べ替える
    @projects = @search.result.page(params[:page])
  end

  # プロジェクト詳細画面
  def show
    # TODO: ransackに変えたい(ransackのradioボタン検索が難しい)
    form_values = params[:plugin_form] ? params[:plugin_form] : { updated: '1' }
    @form = PluginForm.new(form_values)
    @plugins = @form.search_by_project(@project)
  end

  # def new
  #   @project = Project.new
  #   @project.project_versions.build
  # end

  # def create
  #   @project = Project.new(project_params)
  #   if @project.save
  #     redirect_to @project, notice: '正しく登録されました。'
  #   else
  #     render action: :new
  #   end
  # end

  # プロジェクト編集画面
  def edit
  end

  # プロジェクト更新
  def update
    if @project.update_attributes(project_params_for_update)
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
  # Gemfile情報を持っているprojectは更新できない
  def check_updatable
    if @project.gemfile_content
      flash[:alert] = 'このプロジェクトは画面から更新できません。'
      redirect_to @project
    end
  end

  # def project_params
  #   params.require(:project).permit(
  #     :name,
  #     project_versions_attributes: [ :project_id, :installed, :requested, :plugin_name, :_destroy]
  #   )
  # end

  def project_params_for_update
    params.require(:project).permit(
      project_versions_attributes: [ :id, :project_id, :installed, :requested, :plugin_name, :_destroy]
    )
  end

end
