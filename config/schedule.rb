# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#


every 8.hours do
  # Gemfileが更新されているプロジェクトがあれば、ファイルを更新する
  # bundle outdatedコマンドで更新可能なgem一覧を更新する
  runner "Project.update_all"
  # リリースfeed収集
  rake "feeds:generate"
  # セキュリティfeed収集
  rake "security_feed"
end

#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
