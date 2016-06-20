class PluginsController < ApplicationController
  include GemWatcher::ScrapeCveNumber

  before_action :set_plugin, only: [:show, :edit, :update]

  def index
    @search = Plugin.ransack(params[:q])
    @plugins = @search.result.page(params[:page])
  end

  def show
    uri = URI.join(@plugin.source_code_uri, 'blob/master/CHANGELOG.md')
    @release_feeds = @plugin.entries.order('published desc').limit(5)
    @cve_numbers = cve_numbers(uri.to_s)
    @securities = @plugin.security_entries
  end

  def edit
  end

  def update
    if @plugin.update(plugin_params)
      redirect_to @plugin, notice: '正しく更新されました。'
    else
      render action: :edit
    end
  end

  private
  def set_plugin
    @plugin = Plugin.find(params[:id])
  end

  def plugin_params
    params.require(:plugin).permit(:source_code_uri)
  end

end
