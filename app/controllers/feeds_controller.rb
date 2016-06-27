
class FeedsController < ApplicationController

  def index
    @rails_entries = Entry.rails_entries
    entries = Entry.joins(:plugin).where('plugins.name' => 'rails')

    @latest_major_version = entries.maximum(:major_version) #4
    @latest_minor_version = entries.where(major_version: @latest_major_version).maximum(:minor_version) #2

    @search = Entry.newest_plugins.ransack(params[:q])
    @entries = @search.result.order('entries.published desc').page(params[:page])
  end

  def show
    @entry = Entry.find(params[:id])
    entries = Entry.joins(:plugin).where('plugins.name' => 'rails')
    @rails_entries = Entry.rails_entries
    # 同じメジャーバージョンで自分より小さいマイナーバージョンはあるか?
    less_minor_version = nil
    less_major_version = nil
    @rails_entries.each { |e|
      if e != @entry && e.major_version == @entry.major_version && e.minor_version < @entry.minor_version
        less_minor_version = true
      elsif e != @entry && e.major_version < @entry.major_version
        less_major_version = true
      end
    }
    if less_minor_version
      @entries = entries.where(
            major_version: @entry.major_version,
            minor_version: @entry.minor_version
          ).order('published desc')
    else
      @entries = entries.where(["major_version = ? AND minor_version <= ?", @entry.major_version, @entry.minor_version]).order('published desc')
    end
  end
end
