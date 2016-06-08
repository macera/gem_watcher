class PluginsController < ApplicationController

  before_action :set_plugin, only: :show

  def index
    @plugins = Plugin.all
  end

  def show

  end

  private
  def set_plugin
    @plugin = Plugin.find(params[:id])
  end
end
