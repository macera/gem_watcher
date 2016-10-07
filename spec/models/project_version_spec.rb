require 'rails_helper'

RSpec.describe ProjectVersion, type: :model do
  let(:root) { Rails.root.join('spec', 'fixtures') }

  describe 'スコープ' do

    describe '属性によるスコープ' do
      before do
        project1 = create(:project)
        @version1 = create(:version, installed: '4.0.0', newest: '5.0.0', described: true, project: project1)
        @version2 = create(:version, installed: '4.0.0', newest: nil, described: true, project: project1)
        @version3 = create(:version, installed: '4.2.0', newest: '5.0.0', described: true, project: project1)
        @version_dependency = create(:version, described: false, newest: '5.0.0', project: project1)
        @version4 = create(:version, installed: '4.2.0', newest: nil, described: true, vulnerability: true, project: project1)
      end

      describe '.newest_versions' do
        it '最新に更新「可能」なversionのみ取得できること' do
          expect(ProjectVersion.newest_versions).to eq [@version1, @version3, @version_dependency]
        end
      end

      describe '.updated_versions' do
        it '最新に更新「済み」なversionのみ取得できること' do
          expect(ProjectVersion.updated_versions).to eq [@version2, @version4]
        end
      end
      describe '.only_gemfile' do
        it 'gemfileに書かれたversionのみ取得できること' do
          expect(ProjectVersion.only_gemfile).to eq [@version1, @version2, @version3, @version4]
        end
      end
      describe '.no_gemfile' do
        it 'gemfileに書かれていないversionのみ取得できること' do
          expect(ProjectVersion.no_gemfile).to eq [@version_dependency]
        end
      end

      describe '.vulnerable' do
        it 'vulnerabilityがtrueのversionのみ取得できること' do
          expect(ProjectVersion.vulnerable).to eq [@version4]
        end
      end
    end

    describe '.updatable' do
      before do
        @v1 = create(:project_version, installed: '3.2.1', newest: '5.0.0', described: true)
        @v2 = create(:project_version, installed: '4.2.0', newest: '5.0.0', described: true)
        @v3 = create(:project_version, installed: '5.0.1', newest: '5.0.0', described: false)
        @v4 = create(:project_version, installed: '4.0.0', newest: '5.0.0', described: true)
        @v5 = create(:project_version, installed: '4.0.0', newest: nil, described: true)
      end
      it '更新可能なプロジェクトのバージョンのみ取得できること' do
        expect(ProjectVersion.updatable).to eq [@v2, @v4, @v1]
      end
    end

    # describe '.less_than' do
    #   it '引数より小さいメジャーバージョンを取得すること' do
    #     @v1 = create(:project_version, installed: '5.0.0')
    #     @v2 = create(:project_version, installed: '4.0.0')
    #     expect(ProjectVersion.less_than('5.0.0')).to eq [@v2]
    #   end
    #   it '引数より小さいマイナーバージョンを取得すること' do
    #     @v1 = create(:project_version, installed: '4.3.0')
    #     @v2 = create(:project_version, installed: '4.1.0')
    #     expect(ProjectVersion.less_than('4.2.0')).to eq [@v2]
    #   end
    #   it '引数より小さいパッチバージョンを取得すること(1桁目)' do
    #     @v1 = create(:project_version, installed: '5.0.11')
    #     @v2 = create(:project_version, installed: '5.0.1')
    #     expect(ProjectVersion.less_than('5.0.2')).to eq [@v2]
    #   end
    #   it '引数より小さいパッチバージョンを取得すること' do
    #     @v1 = create(:project_version, installed: '0.7.9.2008.10.13')
    #     @v2 = create(:project_version, installed: '0.7.9.2008.08.17')
    #     expect(ProjectVersion.less_than('0.7.9.2008.10.05')).to eq [@v2]
    #   end
    #   it '引数より小さいパッチバージョン(文字列あり)を取得すること' do
    #     pending '英字ありのバージョン対応 保留'
    #     @v1 = create(:project_version, installed: '2.0.0.backport2')
    #     @v2 = create(:project_version, installed: '2.0.0')
    #     @v3 = create(:project_version, installed: '2.0.0.1')
    #     expect(ProjectVersion.less_than('2.0.0.backport1')).to eq [@v2]
    #   end
    # end

    describe '.less_than_patch' do
      it '引数よりパッチバージョンが小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.0.11')
        @v2 = create(:project_version, installed: '5.0.2')
        @v3 = create(:project_version, installed: '5.0.1')
        expect(ProjectVersion.less_than_patch('5.0.11')).to eq [@v2, @v3]
      end
      it '引数よりリビジョンバージョン(文字列)が小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.0.0.5')
        @v2 = create(:project_version, installed: '5.0.0.2')
        @v3 = create(:project_version, installed: '5.0.0.1')
        expect(ProjectVersion.less_than_patch('5.0.0.5')).to eq [@v2, @v3]
      end
      it '引数よりリビジョンバージョン(文字列)が小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '2.0.0.backport2')
        @v2 = create(:project_version, installed: '2.0.0')
        @v3 = create(:project_version, installed: '2.0.0.1')
        expect(ProjectVersion.less_than_patch('2.0.0.1')).to eq [@v1, @v2]
      end
    end

    describe '.less_than_minor' do
      it '引数よりマイナーバージョンより小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.11.0')
        @v2 = create(:project_version, installed: '5.2.0')
        @v3 = create(:project_version, installed: '5.1.0')
        expect(ProjectVersion.less_than_minor('5.11.0')).to eq [@v2, @v3]
      end
      it '引数よりパッチバージョンが小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.0.11')
        @v2 = create(:project_version, installed: '5.0.2')
        @v3 = create(:project_version, installed: '5.0.1')
        expect(ProjectVersion.less_than_minor('5.0.11')).to eq [@v2, @v3]
      end
      it '引数よりリビジョンバージョン(文字列)が小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.0.0.5')
        @v2 = create(:project_version, installed: '5.0.0.2')
        @v3 = create(:project_version, installed: '5.0.0.1')
        expect(ProjectVersion.less_than_minor('5.0.0.5')).to eq [@v2, @v3]
      end
      it '引数よりリビジョンバージョン(文字列)が小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '2.0.0.backport2')
        @v2 = create(:project_version, installed: '2.0.0')
        @v3 = create(:project_version, installed: '2.0.0.1')
        expect(ProjectVersion.less_than_minor('2.0.0.1')).to eq [@v1, @v2]
      end
    end

    describe '.less_than_major' do
      it '引数よりメジャーバージョンより小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.11.0')
        @v2 = create(:project_version, installed: '4.2.0')
        @v3 = create(:project_version, installed: '3.1.0')
        expect(ProjectVersion.less_than_major('5.11.0')).to eq [@v2, @v3]
      end
      it '引数よりマイナーバージョンより小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.11.0')
        @v2 = create(:project_version, installed: '5.2.0')
        @v3 = create(:project_version, installed: '5.1.0')
        expect(ProjectVersion.less_than_major('5.11.0')).to eq [@v2, @v3]
      end
      it '引数よりパッチバージョンが小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.0.11')
        @v2 = create(:project_version, installed: '5.0.2')
        @v3 = create(:project_version, installed: '5.0.1')
        expect(ProjectVersion.less_than_major('5.0.11')).to eq [@v2, @v3]
      end
      it '引数よりリビジョンバージョン(文字列)が小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '5.0.0.5')
        @v2 = create(:project_version, installed: '5.0.0.2')
        @v3 = create(:project_version, installed: '5.0.0.1')
        expect(ProjectVersion.less_than_major('5.0.0.5')).to eq [@v2, @v3]
      end
      it '引数よりリビジョンバージョン(文字列)が小さいバージョンのみ取得できること' do
        @v1 = create(:project_version, installed: '2.0.0.backport2')
        @v2 = create(:project_version, installed: '2.0.0')
        @v3 = create(:project_version, installed: '2.0.0.1')
        expect(ProjectVersion.less_than_major('2.0.0.1')).to eq [@v1, @v2]
      end
    end

    describe '.order_by_version' do
      it 'メジャーバージョン順に並べ替えること' do
        @v1 = create(:project_version, installed: '3.0.0.0')
        @v2 = create(:project_version, installed: '4.0.0.0')
        @v3 = create(:project_version, installed: '5.0.0.0')
        expect(ProjectVersion.order_by_version).to eq [@v3, @v2, @v1]
      end
      it 'マイナーバージョン順に並べ替えること' do
        @v1 = create(:project_version, installed: '4.4.0.0')
        @v2 = create(:project_version, installed: '4.2.0.0')
        @v3 = create(:project_version, installed: '4.15.0.0')
        expect(ProjectVersion.order_by_version).to eq [@v3, @v1, @v2]
      end
      it 'パッチバージョン順に並べ替えること' do
        @v1 = create(:project_version, installed: '4.0.2.0')
        @v2 = create(:project_version, installed: '4.0.3.0')
        @v3 = create(:project_version, installed: '4.0.15.0')
        expect(ProjectVersion.order_by_version).to eq [@v3, @v2, @v1]
      end
      it 'リビジョンバージョン(文字列)順に並べ替えること(数字)' do
        @v1 = create(:project_version, installed: '4.0.0.1')
        @v2 = create(:project_version, installed: '4.0.0')
        @v3 = create(:project_version, installed: '4.0.0.5')
        expect(ProjectVersion.order_by_version).to eq [@v3, @v1, @v2]
      end
      it 'リビジョンバージョン(文字列)順に並べ替えること(英字含む)' do
        @v1 = create(:project_version, installed: '4.0.0.1')
        @v2 = create(:project_version, installed: '4.0.0')
        @v3 = create(:project_version, installed: '4.0.0.a1')  # TODO: 見直し必要
        expect(ProjectVersion.order_by_version).to eq [@v1, @v3, @v2]
      end
    end

    describe '.by_parent_version' do
      before do
        @project = create(:project)
        @plugin = create(:plugin)
        @entry = create(:entry, plugin: @plugin)
        @version = create(:project_version, installed: '5.0.0',
                                            project: @project,
                                            entry:   @entry,
                                            plugin:  @plugin)
        @dep_plugin = create(:plugin)
        @dep_entry = create(:entry, plugin: @dep_plugin)
        @dep_version = create(:project_version, installed: '4.0.0',
                                                 project: @project,
                                                 entry:   @entry,
                                                 plugin:  @dep_plugin)
        @dependency = create(:dependency, plugin: @dep_plugin, entry: @entry)
      end
      it '親gemのバージョンをもとにバージョンを取得すること' do
        expect(@dependency.plugin.project_versions.by_parent_version(@entry)).to eq [@dep_version]
      end
    end

    describe '.uniq_vulnerable_versions' do
      it '脆弱性のあるバージョンを重複なく取得すること' do
        @plugin = create(:plugin)
        @entry = create(:entry)
        @version1 = create(:version, installed: '4.2.0', described: true, vulnerability: true, plugin: @plugin, entry: @entry)
        @version2 = create(:version, installed: '4.2.0', described: true, vulnerability: true, plugin: @plugin, entry: @entry)
        @version3 = create(:version, installed: '5.0.0', described: true, vulnerability: true, plugin: @plugin, entry: @entry)
        expect(ProjectVersion.uniq_vulnerable_versions.pluck(:installed)).to eq ['5.0.0', '4.2.0']
      end
    end
  end

  describe 'クラスメソッド' do
    describe '.update_vulnerable_versions' do
      let(:path1) { File.join(root, 'gems', 'activesupport', 'CVE-2015-3226.yml') }
      let(:path2) { File.join(root, 'gems', 'actionpack', 'CVE-2016-0751.yml') }
      before do
        @project = create(:project)
        @plugin = create(:plugin, name: 'kaminari')
        @entry = create(:entry, plugin: @plugin, title: 'kaminari (0.15.0)')
        @version = create(:version, installed: '0.15.0', described: true, project: @project, entry: @entry, plugin: @plugin)
        @plugin1 = create(:plugin, name: 'activesupport')
        @plugin2 = create(:plugin, name: 'actionpack')

        @entry1 = create(:entry, plugin: @plugin1,
                                 title: 'activesupport (4.0.2)')
        @version1 = create(:version, installed: '4.0.2', described: false, project: @project, entry: @entry1, plugin: @plugin1)
        @entry2 = create(:entry, plugin: @plugin2,
                                 title: 'actionpack (4.0.2)')
        @version2 = create(:version, installed: '4.0.2', described: false, project: @project, entry: @entry2, plugin: @plugin2)
        create(:dependency, requirements: '>= 3.0.0', plugin: @plugin1, entry: @entry)
        create(:dependency, requirements: '>= 3.0.0', plugin: @plugin2, entry: @entry)
        security_advisory_create(path1, @plugin1)
        security_advisory_create(path2, @plugin2)

        # 脆弱性がない
        @project2 = create(:project)
        @new_entry = create(:entry, plugin: @plugin, title: 'kaminari (0.17.0)')
        @new_version = create(:version, installed: '0.17.0', described: true, entry: @new_entry, plugin: @plugin, project: @project2)
        @new_entry1 = create(:entry, plugin: @plugin1,
                                 title: 'activesupport (5.0.0.1)')
        @new_version1 = create(:version, installed: '5.0.0.1', described: false, entry: @new_entry1, plugin: @plugin1, project: @project2)
        @new_entry2 = create(:entry, plugin: @plugin2,
                                 title: 'actionpack (5.0.0.1)')
        @new_version2 = create(:version, installed: '5.0.0.1', described: false, entry: @new_entry2, plugin: @plugin2, project: @project2)
        create(:dependency, requirements: '>= 3.0.0', plugin: @plugin1, entry: @new_entry)
        create(:dependency, requirements: '>= 3.0.0', plugin: @plugin2, entry: @new_entry)

        # 後で脆弱性が追加される
        @project3 = create(:project)
        @old_entry = create(:entry, plugin: @plugin, title: 'kaminari (0.16.0)')
        @old_version = create(:version, installed: '0.16.0', described: true, entry: @old_entry, plugin: @plugin, project: @project3)
        @old_entry1 = create(:entry, plugin: @plugin1,
                                 title: 'activesupport (4.2.1)')
        @old_version1 = create(:version, installed: '4.2.1', described: false, entry: @old_entry1, plugin: @plugin1, project: @project3)
        @old_entry2 = create(:entry, plugin: @plugin2,
                                 title: 'actionpack (4.2.5.1)')
        @old_version2 = create(:version, installed: '4.2.5.1', described: false, entry: @old_entry2, plugin: @plugin2, project: @project3)
        create(:dependency, requirements: '>= 3.0.0', plugin: @plugin1, entry: @old_entry)
        create(:dependency, requirements: '>= 3.0.0', plugin: @plugin2, entry: @old_entry)
      end
      context '初期登録。フラグはnil' do
        before do
          ProjectVersion.update_vulnerable_versions
        end
        context '脆弱性情報がある場合' do
          it 'vulnerabilityフラグはtrueを返却すること' do
            expect(ProjectVersion.find(@version.id).vulnerability).to be true
          end
        end
        context '脆弱性情報がない場合' do
          it 'vulnerabilityフラグはfalseを返却すること' do
            expect(ProjectVersion.find(@old_version.id).vulnerability).to be false
          end
        end
      end
      context 'project_versionが最新に更新した場合' do
        before do
          ProjectVersion.update_vulnerable_versions
          # 新しいバージョンに更新する
          version = ProjectVersion.find(@version.id)
          version.update(installed: '0.17.0', entry: @new_entry)
          version1 = ProjectVersion.find(@version1.id)
          version1.update(installed: '5.0.0.1', entry: @new_entry1)
          version2 = ProjectVersion.find(@version2.id)
          version2.update(installed: '5.0.0.1', entry: @new_entry2)
          ProjectVersion.update_vulnerable_versions
        end
        it 'trueだったフラグがfalseになっていること' do
          expect(ProjectVersion.find(@version.id).vulnerability).to be false
        end
      end
      context '新しい脆弱性情報が追加された場合' do
        let(:path3) { File.join(root, 'gems', 'activesupport', 'CVE-2015-3227.yml') }
        let(:path4) { File.join(root, 'gems', 'actionpack', 'CVE-2016-2098.yml') }
        before do
          ProjectVersion.update_vulnerable_versions
          # 新しい脆弱性情報追加
          security_advisory_create(path3, Plugin.find(@plugin1.id))
          security_advisory_create(path4, Plugin.find(@plugin2.id))
          ProjectVersion.update_vulnerable_versions
        end
        it 'falseだったフラグがtrueになっていること' do
          expect(ProjectVersion.find(@old_version.id).vulnerability).to be true
        end
      end

    end

  end

  describe 'インスタンスメソッド' do
    describe '#security_check' do
      context '依存先に脆弱性がある場合' do
        let(:path1) { File.join(root, 'gems', 'activesupport', 'CVE-2015-3227.yml') }
        let(:path2) { File.join(root, 'gems', 'actionpack', 'CVE-2016-2098.yml') }
        before do
          @project = create(:project)
          @plugin = create(:plugin, name: 'kaminari')
          @entry = create(:entry, plugin: @plugin, title: 'kaminari (0.15.0)')
          @version = create(:version, installed: '0.15.0', project: @project, entry: @entry, plugin: @plugin)
          @plugin1 = create(:plugin, name: 'activesupport')
          @plugin2 = create(:plugin, name: 'actionpack')
          @entry1 = create(:entry, plugin: @plugin1,
                                   title: 'activesupport(4.0.2)')
          @version1 = create(:version, installed: '4.0.2', project: @project, entry: @entry1, plugin: @plugin1)
          @entry2 = create(:entry, plugin: @plugin2,
                                   title: 'actionpack(4.0.2)')
          @version2 = create(:version, installed: '4.0.2', project: @project, entry: @entry2, plugin: @plugin2)
          create(:dependency, requirements: '>= 3.0.0', plugin: @plugin1, entry: @entry)
          create(:dependency, requirements: '>= 3.0.0', plugin: @plugin2, entry: @entry)
          security_advisory_create(path1, @plugin1)
          security_advisory_create(path2, @plugin2)
        end
        it '依存先のProjectVersionを2件返却すること' do
          expect(@version.security_check).to eq [@version1, @version2]
        end
      end

      context '自身のgemに脆弱性がある場合' do
        let(:path) { File.join(root, 'gems', 'paperclip', 'CVE-2015-2963.yml') }
        before do
          @project = create(:project)
          @plugin = create(:plugin, name: 'paperclip')
          @entry = create(:entry, plugin: @plugin, title: 'paperclip (3.5.2)')
          @version = create(:version, installed: '3.5.2', project: @project, entry: @entry, plugin: @plugin)

          security_advisory_create(path, @plugin)
        end
        it '自身のProjectVersionを返却すること' do
          expect(@version.security_check).to eq [@version]
        end
      end

    end

    describe '#alert_status' do
      context '依存先に脆弱性がある場合' do
        let(:path1) { File.join(root, 'gems', 'activesupport', 'CVE-2015-3227.yml') }
        let(:path2) { File.join(root, 'gems', 'actionpack', 'CVE-2016-2098.yml') }
        before do
          @project = create(:project)
          @plugin = create(:plugin, name: 'kaminari')
          @entry = create(:entry, plugin: @plugin, title: 'kaminari (0.15.0)')
          @version = create(:version, installed: '0.15.0', project: @project, entry: @entry, plugin: @plugin)
          @plugin1 = create(:plugin, name: 'activesupport')
          @plugin2 = create(:plugin, name: 'actionpack')
          @entry1 = create(:entry, plugin: @plugin1,
                                   title: 'activesupport(4.0.2)')
          @version1 = create(:version, installed: '4.0.2', project: @project, entry: @entry1, plugin: @plugin1)
          @entry2 = create(:entry, plugin: @plugin2,
                                   title: 'actionpack(4.0.2)')
          @version2 = create(:version, installed: '4.0.2', project: @project, entry: @entry2, plugin: @plugin2)
          create(:dependency, requirements: '>= 3.0.0', plugin: @plugin1, entry: @entry)
          create(:dependency, requirements: '>= 3.0.0', plugin: @plugin2, entry: @entry)
          security_advisory_create(path1, @plugin1)
          security_advisory_create(path2, @plugin2)
        end
        it 'yellowを返却すること' do
          expect(@version.alert_status).to eq 'yellow'
        end
      end
      context '自身のgemに脆弱性がある場合' do
        let(:path) { File.join(root, 'gems', 'paperclip', 'CVE-2015-2963.yml') }
        before do
          @project = create(:project)
          @plugin = create(:plugin, name: 'paperclip')
          @entry = create(:entry, plugin: @plugin, title: 'paperclip (3.5.2)')
          @version = create(:version, installed: '3.5.2', project: @project, entry: @entry, plugin: @plugin)

          security_advisory_create(path, @plugin)
        end
        it 'redを返却すること' do
          expect(@version.alert_status).to eq 'red'
        end
      end
    end

    describe '#security_alert?' do
      context '依存先に脆弱性がある場合' do
        let(:path1) { File.join(root, 'gems', 'activesupport', 'CVE-2015-3227.yml') }
        let(:path2) { File.join(root, 'gems', 'actionpack', 'CVE-2016-2098.yml') }
        before do
          @project = create(:project)
          @plugin = create(:plugin, name: 'kaminari')
          @entry = create(:entry, plugin: @plugin, title: 'kaminari (0.15.0)')
          @version = create(:version, installed: '0.15.0', project: @project, entry: @entry, plugin: @plugin)
          @plugin1 = create(:plugin, name: 'activesupport')
          @plugin2 = create(:plugin, name: 'actionpack')
          @entry1 = create(:entry, plugin: @plugin1,
                                   title: 'activesupport(4.0.2)')
          @version1 = create(:version, installed: '4.0.2', project: @project, entry: @entry1, plugin: @plugin1)
          @entry2 = create(:entry, plugin: @plugin2,
                                   title: 'actionpack(4.0.2)')
          @version2 = create(:version, installed: '4.0.2', project: @project, entry: @entry2, plugin: @plugin2)
          create(:dependency, requirements: '>= 3.0.0', plugin: @plugin1, entry: @entry)
          create(:dependency, requirements: '>= 3.0.0', plugin: @plugin2, entry: @entry)
          security_advisory_create(path1, @plugin1)
          security_advisory_create(path2, @plugin2)
        end
        it 'trueを返却すること' do
          expect(@version.security_alert?).to be true
        end
      end
      context '自身のgemに脆弱性がある場合' do
        let(:path) { File.join(root, 'gems', 'paperclip', 'CVE-2015-2963.yml') }
        before do
          @project = create(:project)
          @plugin = create(:plugin, name: 'paperclip')
          @entry = create(:entry, plugin: @plugin, title: 'paperclip (3.5.2)')
          @version = create(:version, installed: '3.5.2', project: @project, entry: @entry, plugin: @plugin)

          security_advisory_create(path, @plugin)
        end
        it 'redを返却すること' do
          expect(@version.security_alert?).to be true
        end
      end
    end

    it_behaves_like 'display_version'
    it_behaves_like 'versioning'
  end

  describe 'コールバック' do
    describe '#set_plugin_name' do
    end
    describe '#set_versions' do
    end
    describe 'with_plugin_info' do
    end
    describe 'destroy_with_plugin_name' do
    end
  end

  describe 'プライベートメソッド' do
    describe '#newest_version' do
    end
  end

end
