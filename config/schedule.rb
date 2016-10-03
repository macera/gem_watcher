# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, 'log/crontab.log'
set :environment, :production

# テスト
#set :environment, :development
# every '*/1 * * * *' do

every 8.hours do
  # 新規のプロジェクトがあれば追加する
  runner "Project.add_projects"
  # Gemfileが更新されているプロジェクトがあれば、ファイルを更新する
  # bundle outdatedコマンドで更新可能なgem一覧を更新する
  runner "Project.update_projects"
  # リリースfeed(version情報)収集
  rake "feeds:generate"
  # versionの依存情報を取得
  runner "Plugin.create_runtime_dependencies"
  # セキュリティDB情報更新
  runner "SecurityAdvisory.source_update"
  # セキュリティ情報取得
  runner "SecurityAdvisory.all_update"
  # ProjectVersionに脆弱性フラグを登録する
  runner "ProjectVersion.update_vulnerable_versions"
  # セキュリティfeed収集
  #rake "security_feed:generate"
end

#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
