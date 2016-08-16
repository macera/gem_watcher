require 'rails_helper'

RSpec.describe SecurityEntry, type: :model do
  describe 'コールバック' do
    describe '.create_created_table_log' do
      before do
        @plugin = create(:plugin)
        @security_entry = SecurityEntry.new(
          title:     'セキュリティタイトル',
          content:   'サマリー',
          author:    '著者',
          url:       'https://groups.google.com/d/topic/ruby-security-ann/xxx',
          published: Time.now,
          genre:     0,
          plugin:    @plugin
        )
      end
      it "create後コールバックを呼び出すこと" do
        expect(@security_entry).to receive(:create_created_table_log)
        @security_entry.save
      end
      it "ログを作成すること" do
        expect{ @security_entry.save }.to change{ CronLog.count }.by(1)
      end
    end
  end
end