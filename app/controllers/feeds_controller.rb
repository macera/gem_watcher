
class FeedsController < ApplicationController
  require "feedjira"

  def index
    @entries = Entry.all.order('published desc')
  end

  def show
  end
end
