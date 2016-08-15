require 'rails_helper'

RSpec.describe CronLog, type: :model do

  describe 'クラスメソッド' do
    describe 'クラスメソッド' do
      describe '.error_create' do
        it 'エラーログを作成すること' do
          expect{
            CronLog.error_create(table_name: 'project', content: "メソッドでエラーが発生")
          }.to change{ CronLog.count }.by(1)
        end
      end
      describe '.success_table' do
        it '成功ログを作成すること' do
          expect{
            CronLog.success_table('project', "プロジェクト名", :create)
          }.to change{ CronLog.count }.by(1)
        end
      end
    end
  end

end