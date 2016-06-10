class PluginsController < ApplicationController
  include GemWatcher::ScrapeCveNumber

  before_action :set_plugin, only: :show

  def index
    @plugins = Plugin.all
  end

  def show
    uri = URI.join(@plugin.source_code_uri, 'blob/master/CHANGELOG.md')
    @release_feeds = @plugin.entries.order('published desc').limit(3)
    @cve_numbers = cve_numbers(uri.to_s)
    @securities = @plugin.security_entries
  end

  private
  def set_plugin
    @plugin = Plugin.find(params[:id])
  end
end
