require 'rails_helper'

RSpec.describe CronLogsHelper do

  describe '#table_lists' do
    context 'テーブルの配列を返却すること' do
      it 'nilを返却すること' do
        expect(helper.table_lists).to eq(
          [
            ['プロジェクト', 'project'],
            ['Gem', 'plugin'],
            ['リリースフィード', 'entry'],
            ['Dependency', 'dependency'],
            ['セキュリティフィード', 'security_entry'],
            ['脆弱性情報', 'security_advisory'],
          ]
        )
      end
    end
  end
end