class CronLogsController < ApplicationController

  # ログ一覧画面
  def index
    @search = CronLog.all.ransack(params[:q])
    @logs = @search.result.order('created_at desc').page(params[:page])
  end
end
