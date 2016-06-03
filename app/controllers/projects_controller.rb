class ProjectsController < ApplicationController
  before_action :set_project, only: :show
  def index
    @projects = Project.all
  end

  def show
  end

  def update_all
    Project.update_all
    redirect_to action: :index
  end

  private
  def set_project
    @project = Project.find(params[:id])
  end
end
