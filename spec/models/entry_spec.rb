require 'rails_helper'

RSpec.describe Entry, type: :model do

  describe 'バリデーション' do
    it { is_expected.to validate_numericality_of(:major_version).only_integer }
    it { is_expected.to validate_numericality_of(:minor_version).only_integer }
    it { is_expected.to validate_numericality_of(:patch_version).only_integer }
  end

  describe 'スコープ' do

    describe '.rails_entries' do
      before do
        @plugin = create(:plugin, name: 'rails')
        @rails2_1 = create(:entry, title: 'rails (2.2.3)',    published: Time.now - 2.day, plugin: @plugin)
        @rails3_1 = create(:entry, title: 'rails (3.2.22.4)', published: Time.now - 2.day, plugin: @plugin)
        @rails3_2 = create(:entry, title: 'rails (3.2.22.5)', published: Time.now - 1.day, plugin: @plugin)
        @rails4_1 = create(:entry, title: 'rails (4.0.13)',   published: Time.now - 2.day, plugin: @plugin)
        @rails4_2 = create(:entry, title: 'rails (4.1.16)',   published: Time.now - 1.day, plugin: @plugin)
        @rails4_3 = create(:entry, title: 'rails (4.2.7)',    published: Time.now - 2.day, plugin: @plugin)
        @rails4_4 = create(:entry, title: 'rails (4.2.7.1)',  published: Time.now - 1.day, plugin: @plugin)
        @rails5_1 = create(:entry, title: 'rails (5.0.0)',    published: Time.now - 2.day, plugin: @plugin)
        @rails5_2 = create(:entry, title: 'rails (5.0.0.1)',  published: Time.now - 1.day, plugin: @plugin)
      end
      it '指定したrailsのバージョン系列の最新一覧を取得すること' do
        expect(Entry.rails_entries).to eq [@rails5_2, @rails4_4, @rails4_2, @rails3_2]
      end
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
        @entry1 = create(:entry, plugin: @plugin, title: 'rails (1.1.1.1)')
        @entry2 = create(:entry, plugin: @plugin, title: 'rails (1.1.3)')
        @entry3 = create(:entry, plugin: @plugin, title: 'rails (1.1.2.1)')
        @entry4 = create(:entry, plugin: @plugin, title: 'rails (1.1.2.2)')
      end
      context 'patch_versionに英字が含まれている場合' do
        it '正しくソートすること' do
          expect(Entry.order_by_version).to eq [@entry2, @entry4, @entry3, @entry1]
        end
      end
      context 'revision_versionに英字が含まれていない場合' do
        before do
          @entry5 = create(:entry, plugin: @plugin, title: 'rails (1.1.1.backport1)')
          @entry6 = create(:entry, plugin: @plugin, title: 'rails (1.1.1.backport2)')
          @entry7 = create(:entry, plugin: @plugin, title: 'rails (1.1.1.0)')
        end
        # 1.1
        # 1.backport2
        # 1.backport1
        # 1.0
        it '正しくソートすること' do
          expect(Entry.order_by_version).to eq [@entry2, @entry4, @entry3, @entry1, @entry6, @entry5, @entry7]
        end
      end

    end

  end

  describe 'クラスメソッド' do
    describe '.update_all' do
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
      context '正常系' do
        let(:rss) { File.read("spec/fixtures/rails_versions_atom_little.xml") } # 3件のentry
        it 'entryが作成されること' do
          expect{ Entry.update_list(@plugin) }.to change{ Entry.count }.by(3)
        end
      end
      context '異常系' do
        context 'patch_versionに英字が含まれている場合' do
          let(:rss) { File.read("spec/fixtures/abnormal_rails_versions_atom_little.xml") }
          it 'entryが作成されること' do
            Entry.update_list(@plugin)
            expect(Entry.last.version).to eq '4.0.a1.a1'
            expect(Entry.last.patch_version).to be nil
            expect(Entry.last.revision_version).to eq 'a1.a1'
          end
          it 'entryが作成されること' do
            expect{ Entry.update_list(@plugin) }.to change{ Entry.count }.by(1)
          end
        end
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
      context 'マイナー、パッチ、リビジョンバージョン全てがある場合' do
        let(:entry) { create(:entry, title: 'rails (0.17.0.1)') }
        it 'versionを正しく返却すること' do
          expect(entry.version).to eq '0.17.0.1'
        end
      end
      context 'マイナーとパッチバージョン両方がある場合' do
        let(:entry) { create(:entry, title: 'rails (0.17.0)') }
        it 'versionを正しく返却すること' do
          expect(entry.version).to eq '0.17.0'
        end
      end
      context 'マイナーバージョンがある場合' do
        let(:entry) { create(:entry, title: 'rails (0.17)') }
        it 'versionを正しく返却すること' do
          expect(entry.version).to eq '0.17'
        end
      end
      context 'マイナーバージョン以降がない場合' do
        let(:entry) { create(:entry, title: 'rails (1)') }
        it 'versionを正しく返却すること' do
          expect(entry.version).to eq '1'
        end
      end
    end

    describe '#updatable_project_versions_by_series' do
      before do
        @plugin = create(:plugin, name: 'rails')
        @rails2_1 = create(:entry, title: 'rails (2.2.3)',    published: Time.now - 2.day, plugin: @plugin)
        @rails3_1 = create(:entry, title: 'rails (3.2.22.4)', published: Time.now - 2.day, plugin: @plugin)
        @rails3_2 = create(:entry, title: 'rails (3.2.22.5)', published: Time.now - 1.day, plugin: @plugin)
        @rails4_1 = create(:entry, title: 'rails (4.0.13)',   published: Time.now - 2.day, plugin: @plugin)
        @rails4_2 = create(:entry, title: 'rails (4.1.16)',   published: Time.now - 1.day, plugin: @plugin)
        @rails4_3 = create(:entry, title: 'rails (4.2.7)',    published: Time.now - 2.day, plugin: @plugin)
        @rails4_4 = create(:entry, title: 'rails (4.2.7.1)',  published: Time.now - 1.day, plugin: @plugin)
        @rails5_1 = create(:entry, title: 'rails (5.0.0)',    published: Time.now - 2.day, plugin: @plugin)
        @rails5_2 = create(:entry, title: 'rails (5.0.0.1)',  published: Time.now - 1.day, plugin: @plugin)
        @entries = Entry.rails_entries
        @version1 = create(:project_version, plugin: @plugin, entry: @rails2_1, installed: '2.2.3')
        @version2 = create(:project_version, plugin: @plugin, entry: @rails3_1, installed: '3.2.22.4')
        @version3 = create(:project_version, plugin: @plugin, entry: @rails3_2, installed: '3.2.22.5')
        @version4 = create(:project_version, plugin: @plugin, entry: @rails4_1, installed: '4.0.13')
        @version5 = create(:project_version, plugin: @plugin, entry: @rails4_2, installed: '4.1.16')
        @version6 = create(:project_version, plugin: @plugin, entry: @rails4_3, installed: '4.2.7')
        @version7 = create(:project_version, plugin: @plugin, entry: @rails4_4, installed: '4.2.7.1')
        @version8 = create(:project_version, plugin: @plugin, entry: @rails5_1, installed: '5.0.0')
        @version9 = create(:project_version, plugin: @plugin, entry: @rails5_2, installed: '5.0.0.1')
      end

      context '同じメジャーバージョンで自分より小さいマイナーバージョンがある場合' do
        it '4.2系のプロジェクトバージョンを返却すること' do
          expect(@rails4_4.updatable_project_versions_by_series(@entries)).to eq [@version6]
        end
      end
      context '同じメジャーバージョンで自分より小さいマイナーバージョンがない場合' do
        context '最も小さいメジャーバージョンの場合' do
          it '2系と3系のプロジェクトバージョンを返却すること' do
            expect(@rails3_2.updatable_project_versions_by_series(@entries)).to eq [@version1, @version2]
          end
        end
        context '最も小さいメジャーバージョンではない場合' do
          it '4.1系、4.0系のプロジェクトバージョンを返却すること' do
            expect(@rails4_2.updatable_project_versions_by_series(@entries)).to eq [@version4]
          end
          it '5系のプロジェクトバージョンを返却すること' do
            expect(@rails5_2.updatable_project_versions_by_series(@entries)).to eq [@version8]
          end
        end
      end
    end

    describe '#less_than_minor_version?' do
      before do
        @plugin = create(:plugin, name: 'rails')
        @rails2_1 = create(:entry, title: 'rails (2.2.3)',    published: Time.now - 2.day, plugin: @plugin)
        @rails3_1 = create(:entry, title: 'rails (3.2.22.4)', published: Time.now - 2.day, plugin: @plugin)
        @rails3_2 = create(:entry, title: 'rails (3.2.22.5)', published: Time.now - 1.day, plugin: @plugin)
        @rails4_1 = create(:entry, title: 'rails (4.0.13)',   published: Time.now - 2.day, plugin: @plugin)
        @rails4_2 = create(:entry, title: 'rails (4.1.16)',   published: Time.now - 1.day, plugin: @plugin)
        @rails4_3 = create(:entry, title: 'rails (4.2.7)',    published: Time.now - 2.day, plugin: @plugin)
        @rails4_4 = create(:entry, title: 'rails (4.2.7.1)',  published: Time.now - 1.day, plugin: @plugin)
        @rails5_1 = create(:entry, title: 'rails (5.0.0)',    published: Time.now - 2.day, plugin: @plugin)
        @rails5_2 = create(:entry, title: 'rails (5.0.0.1)',  published: Time.now - 1.day, plugin: @plugin)
        @entries = Entry.rails_entries
      end
      context '同じメジャーバージョンで自分より小さいマイナーバージョンがある場合' do
        it 'trueを返却すること' do
          expect(@rails4_4.less_than_minor_version?(@entries)).to be true
        end
      end
      context '同じメジャーバージョンで自分より小さいマイナーバージョンがない場合' do
        it 'falseを返却すること' do
          expect(@rails4_2.less_than_minor_version?(@entries)).to be false
        end
      end
    end

    describe '#least_major_version?' do
      before do
        @plugin = create(:plugin, name: 'rails')
        @rails2_1 = create(:entry, title: 'rails (2.2.3)',    published: Time.now - 2.day, plugin: @plugin)
        @rails3_1 = create(:entry, title: 'rails (3.2.22.4)', published: Time.now - 2.day, plugin: @plugin)
        @rails3_2 = create(:entry, title: 'rails (3.2.22.5)', published: Time.now - 1.day, plugin: @plugin)
        @rails4_1 = create(:entry, title: 'rails (4.0.13)',   published: Time.now - 2.day, plugin: @plugin)
        @rails4_2 = create(:entry, title: 'rails (4.1.16)',   published: Time.now - 1.day, plugin: @plugin)
        @rails4_3 = create(:entry, title: 'rails (4.2.7)',    published: Time.now - 2.day, plugin: @plugin)
        @rails4_4 = create(:entry, title: 'rails (4.2.7.1)',  published: Time.now - 1.day, plugin: @plugin)
        @rails5_1 = create(:entry, title: 'rails (5.0.0)',    published: Time.now - 2.day, plugin: @plugin)
        @rails5_2 = create(:entry, title: 'rails (5.0.0.1)',  published: Time.now - 1.day, plugin: @plugin)
        @entries = Entry.rails_entries
      end
      context '最も小さいメジャーバージョンの場合' do
        it 'trueを返却すること' do
          expect(@rails3_2.least_major_version?(@entries)).to be true
        end
      end
      context '最も小さいメジャーバージョンではない場合' do
        it 'falseを返却すること' do
          expect(@rails4_2.least_major_version?(@entries)).to be false
        end
      end
    end

    it_behaves_like 'versioning'

  end

  describe 'コールバック' do
    describe '#set_versions' do
    end
  end

end
