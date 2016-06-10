
class FeedsController < ApplicationController
  require "feedjira"

  def index
    @entries = Entry.newest_plugins.order('published desc')
  end

  def show
  end
end
