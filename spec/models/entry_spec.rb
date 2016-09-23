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

    describe '.order_by_version' do
      before do
        @plugin = create(:plugin)
        create(:version, plugin: @plugin)
        @entry1 = create(:entry, plugin: @plugin, major_version: 1, minor_version: 1, patch_version: '1.1')
        @entry2 = create(:entry, plugin: @plugin, major_version: 1, minor_version: 1, patch_version: '3')
        @entry3 = create(:entry, plugin: @plugin, major_version: 1, minor_version: 1, patch_version: '2.1')
        @entry4 = create(:entry, plugin: @plugin, major_version: 1, minor_version: 1, patch_version: '2.2')
      end
      context 'patch_versionに英字が含まれている場合' do
        it '正しくソートすること' do
          expect(Entry.order_by_version).to eq [@entry2, @entry4, @entry3, @entry1]
        end
      end
      context 'patch_versionに英字が含まれていない場合' do
        before do
          @entry5 = create(:entry, plugin: @plugin, major_version: 1, minor_version: 1, patch_version: '1.backport1')
          @entry6 = create(:entry, plugin: @plugin, major_version: 1, minor_version: 1, patch_version: '1.backport2')
          @entry7 = create(:entry, plugin: @plugin, major_version: 1, minor_version: 1, patch_version: '1.0')
        end
        # 1.1
        # 1.backport2(=1.0.2文字部分は0.0として扱う)
        # 1.backport1(=1.0.1文字部分は0.0として扱う)
        # 1.0
        it '正しくソートすること' do
          expect(Entry.order_by_version).to eq [@entry2, @entry4, @entry3, @entry1, @entry6, @entry5, @entry7]
        end
      end

    end

  end

  describe 'クラスメソッド' do
    describe '.update_all' do
      let(:rss) { File.read("spec/fixtures/rails_versions_atom_little.xml") } # 3件のentry
      let(:freedjira_parsed) { Feedjira::Parser::Atom.parse(rss) }
      let(:rss_path) { URI.join("#{Settings.feeds.rubygem}rails/versions.atom").to_s }
      before do
        @plugin = create(:plugin, name: 'rails')
        allow(Gems).to receive(:info).with('rails').and_return(
          {"name" => "rails"}
        )
        allow(Feedjira::Feed).to receive(:fetch_and_parse).with(rss_path).and_return(
          freedjira_parsed
        )
      end
      it 'entryが作成されること' do
        expect{ Entry.update_list(@plugin) }.to change{ Entry.count }.by(3)
      end
    end

    describe '.version_from_feed' do
      context 'マイナーとパッチバージョン両方がある場合' do
        it 'versionを正しく返却すること' do
          expect(Entry.version_from_feed('kaminari (0.17.0)')).to eq ['0', '17', '0']
        end
      end
      context 'マイナーバージョンがある場合' do
        it 'versionを正しく返却すること' do
          expect(Entry.version_from_feed('kaminari (0.17)')).to eq ['0', '17']
        end
      end
      context 'マイナーバージョン以降がない場合' do
        it 'versionを正しく返却すること' do
          expect(Entry.version_from_feed('kaminari (1)')).to eq  ['1']
        end
      end
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
