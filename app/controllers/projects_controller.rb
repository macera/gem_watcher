class ProjectsController < ApplicationController

  before_action :set_project, only: [:show, :edit, :update]
  before_action :check_updatable, only: [:edit, :update]

  # プロジェクト一覧画面
  def index
    # 脆弱性情報のあるproject_ids
    @security_alert_ids = []
    Project.all.each do |project|
      @security_alert_ids << project.id if project.has_security_alert?
    end

    @search = Project.security_order(@security_alert_ids).ransack(params[:q])
    @projects = @search.result.page(params[:page])
  end

  # プロジェクト詳細画面
  def show
    # TODO: ransackに変えたい(ransackのradioボタン検索が難しい)
    @form = PluginForm.new(form_params)
    @plugins = @form.search_by_project(@project)
  end

  # プロジェクト編集画面
  def edit
  end

  # プロジェクト更新
  def update
    # TODO: entryに紐づけないといけない!!
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

  def form_params
    if params[:plugin_form]
      params[:plugin_form].permit(:name, :updated)
    else
      { updated: '1' }
    end
  end

  def project_params_for_update
    params.require(:project).permit(
      project_versions_attributes: [ :id, :project_id, :installed, :requested, :plugin_name, :described, :_destroy]
    )
  end

end
