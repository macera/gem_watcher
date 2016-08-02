class VersionsController < ApplicationController

  before_action :set_version, only: [:show]

  # gem version詳細画面
  def show
    @release_feeds = @plugin.entries.order('published desc').limit(10)
    @securities = @plugin.security_entries.where(published: (@version.published.ago(43200))..(@version.published.since(43200)) )
    @dependencies = @version.dependencies
  end

  private
  def set_version
    @plugin = Plugin.find_by(id: params[:plugin_id])
    @version = @plugin.entries.find_by(id: params[:id])
    unless @version
      redirect_to root_path
    end
  end

end