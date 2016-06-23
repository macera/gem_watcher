class CronLogsController < ApplicationController
  def index
    @logs = CronLog.all.order('created_at desc').page(params[:page])
  end
end
