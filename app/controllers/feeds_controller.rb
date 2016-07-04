
class FeedsController < ApplicationController

  before_action :set_feed, only: [:show]

  # トップ画面 フィード一覧
  def index
    @rails_entries = Entry.rails_entries

    @search = Entry.newest_plugins.ransack(params[:q])
    @entries = @search.result.order('published desc').page(params[:page])
  end

  # フィード(バージョン)詳細画面
  def show
    entries = Entry.joins(:plugin).where('plugins.name' => 'rails')
    # 同じメジャーバージョンで自分より小さいマイナーバージョンはあるか?
    less_minor_version = nil
    @rails_entries.each { |e|
      if e != @entry && e.major_version == @entry.major_version && e.minor_version < @entry.minor_version
        less_minor_version = true
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

  private
    def set_feed
      @rails_entries = Entry.rails_entries
      @entry = @rails_entries.where(id: params[:id]).first
      # 表示しているrails release feeds以外のバージョン詳細画面は遷移できない
      unless @entry
        flash[:alert] = '指定の画面は存在しません。'
        redirect_to action: :index
      end
    end
end
