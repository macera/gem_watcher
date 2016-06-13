require 'rails_helper'

RSpec.describe Entry, type: :model do

  describe 'スコープ' do
    describe '.newest_plugins' do
      before do
        plugin1 = create(:plugin)
        @entry1 = create(:entry, title: 'title1', published: Time.now - 3.day, plugin: plugin1)
        @entry2 = create(:entry, title: 'title2', published: Time.now - 2.day, plugin: plugin1)
        @entry3 = create(:entry, title: 'title3', published: Time.now - 1.day, plugin: plugin1)
        plugin2 = create(:plugin)
        @entry4 = create(:entry, title: 'title1', published: Time.now - 6.day, plugin: plugin2)
        @entry5 = create(:entry, title: 'title2', published: Time.now - 5.day, plugin: plugin2)
        @entry6 = create(:entry, title: 'title3', published: Time.now - 4.day, plugin: plugin2)
      end

      it 'plugin毎の最も最新のentryのみ取得できること' do
        expect(Entry.newest_plugins).to eq [@entry3, @entry6]
      end

    end
  end

end
