class VersionsController < ApplicationController

  before_action :set_plugin
  before_action :set_version, only: [:show]

  def index
    @release_feeds = @plugin.entries.order('published desc').limit(5)
    @entries = @plugin.entries.order_by_version
  end


  # gem version詳細画面
  def show
    @release_feeds = @plugin.entries.order('published desc').limit(5)
    @vulnerable_securities = @version.vulnerable_securities.order('date desc')
    @patched_securities = @version.patched_securities.order('date desc')
    @dependencies = @version.dependencies
  end

  private
  def set_plugin
    @plugin = Plugin.find_by(id: params[:plugin_id])
    unless @plugin
      redirect_to root_path
    end
  end

  def set_version
    @version = @plugin.entries.find_by(id: params[:id])
    unless @version
      redirect_to plugin_versions_path
    end
  end

end