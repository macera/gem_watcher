class VersionsController < ApplicationController

  before_action :set_plugin
  before_action :set_version, only: [:show]

  def index
    @release_feeds = @plugin.entries.order('published desc').limit(10)
    @entries = @plugin.entries.order('major_version desc, minor_version desc, patch_version desc')
  end


  # gem version詳細画面
  def show
    @release_feeds = @plugin.entries.order('published desc').limit(10)
    @securities = SecurityAdvisory.check_gem(@plugin, @version.version)

    #@plugin.security_entries.where(published: (@version.published.ago(43200))..(@version.published.since(43200)) )
    @dependencies = @version.dependencies
  end

  private
  def set_plugin
    @plugin = Plugin.find_by(id: params[:plugin_id])
  end

  def set_version
    @version = @plugin.entries.find_by(id: params[:id])
    unless @version
      redirect_to root_path
    end
  end

end