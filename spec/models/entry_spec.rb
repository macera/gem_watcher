require 'rails_helper'

RSpec.describe Entry, type: :model do

  describe 'スコープ' do

    describe '.rails_entries' do
    end

    describe '.newest_plugins' do
      before do
        plugin1 = create(:plugin)
        create(:version, plugin: plugin1)
        @entry1 = create(:entry, title: 'title1', published: Time.now - 3.day, plugin: plugin1)
        @entry2 = create(:entry, title: 'title2', published: Time.now - 2.day, plugin: plugin1)
        @entry3 = create(:entry, title: 'title3', published: Time.now - 1.day, plugin: plugin1)
        plugin2 = create(:plugin)
        create(:version, plugin: plugin2)
        @entry4 = create(:entry, title: 'title1', published: Time.now - 6.day, plugin: plugin2)
        @entry5 = create(:entry, title: 'title2', published: Time.now - 5.day, plugin: plugin2)
        @entry6 = create(:entry, title: 'title3', published: Time.now - 4.day, plugin: plugin2)
      end

      it 'plugin毎の最も最新のentryのみ取得できること' do
        expect(Entry.newest_plugins).to eq [@entry3, @entry6]
      end

    end
  end

  describe 'クラスメソッド' do
    describe '.update_all' do
    end
  end

  describe 'インスタンスメソッド' do
    describe '#version' do
      context 'マイナーとパッチバージョン両方がある場合' do
        let(:entry) { create(:entry, major_version: 0, minor_version: 17, patch_version: "0") }
        it 'versionを正しく返却すること' do
          expect(entry.version).to eq '0.17.0'
        end
      end
      context 'マイナーバージョンがある場合' do
        let(:entry) { create(:entry, major_version: 0, minor_version: 17, patch_version: nil) }
        it 'versionを正しく返却すること' do
          expect(entry.version).to eq '0.17'
        end
      end
      context 'マイナーバージョン以降がない場合' do
        let(:entry) { create(:entry, major_version: 1, minor_version: nil, patch_version: nil) }
        it 'versionを正しく返却すること' do
          expect(entry.version).to eq '1'
        end
      end
    end
  end

end
