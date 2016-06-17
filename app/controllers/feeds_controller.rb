
class FeedsController < ApplicationController
  require "feedjira"

  def index
    @entries = Entry.newest_plugins.order('published desc').page(params[:page])
  end

  def show
  end
end
