
class FeedsController < ApplicationController

  def index
    @search = Entry.newest_plugins.ransack(params[:q])
    @entries = @search.result.order('entries.published desc').page(params[:page])
  end

  def show
  end
end
