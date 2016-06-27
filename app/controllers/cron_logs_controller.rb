class CronLogsController < ApplicationController
  def index
    @search = CronLog.all.ransack(params[:q])
    @logs = @search.result.order('created_at desc').page(params[:page])
  end
end
