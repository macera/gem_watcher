class PluginsController < ApplicationController
  include GemWatcher::ScrapeCveNumber

  before_action :set_plugin, only: [:show]

  # gem詳細画面
  def show
    @release_feeds = @plugin.entries.order('published desc').limit(5)
    @securities = @plugin.security_entries
    # source_code_uriがない場合もあるためひとまずこれでしのぐ
    if @plugin.source_code_uri
      uri = URI.join(@plugin.source_code_uri, 'blob/master/CHANGELOG.md')
      @cve_numbers = cve_numbers(uri.to_s)
    end
  end

  private
  def set_plugin
    @plugin = Plugin.find(params[:id])
  end

end
