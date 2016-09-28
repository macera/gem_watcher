class PluginsController < ApplicationController
  before_action :set_plugin, only: [:show]

  # gem詳細画面
  def show
    @release_feeds = @plugin.entries.order('published desc').limit(5)
    @vulnerable_securities = @plugin.security_advisories.order('date desc')
  end

  private
  def set_plugin
    @plugin = Plugin.find(params[:id])
  end

end
