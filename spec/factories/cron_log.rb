FactoryGirl.define do
  factory :cron_log do
     table_name 'project'
     content    'ログの内容です'
     state      CronLog.states[:success]
  end
end
