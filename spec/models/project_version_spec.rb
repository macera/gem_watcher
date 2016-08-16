require 'rails_helper'

RSpec.describe ProjectVersion, type: :model do
  let(:root) { Rails.root.join('spec', 'fixtures') }

  describe 'スコープ' do
    before do
      project1 = create(:project)
      @version1 = create(:version, installed: '4.0.0', newest: '5.0.0', described: true, project: project1)
      @version2 = create(:version, installed: '4.0.0', newest: nil, described: true, project: project1)
      @version3 = create(:version, installed: '4.2.0', newest: '5.0.0', described: true, project: project1)
      @version_dependency = create(:version, described: false, newest: '5.0.0', project: project1)
    end

    describe '.newest_versions' do
      it '最新に更新「可能」なversionのみ取得できること' do
        expect(ProjectVersion.newest_versions).to eq [@version1, @version3, @version_dependency]
      end
    end

    describe '.updated_versions' do
      it '最新に更新「済み」なversionのみ取得できること' do
        expect(ProjectVersion.updated_versions).to eq [@version2]
      end
    end
    describe '.only_gemfile' do
      it 'gemfileに書かれたgemのみ取得できること' do
        expect(ProjectVersion.only_gemfile).to eq [@version1, @version2, @version3]
      end
    end
    describe '.no_gemfile' do
      it 'gemfileに書かれていないgemのみ取得できること' do
        expect(ProjectVersion.no_gemfile).to eq [@version_dependency]
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
          @entry = create(:entry, plugin: @plugin,
                                  major_version: 0,
                                  minor_version: 15,
                                  patch_version: 0
                          )
          @version = create(:version, installed: '0.15.0', project: @project, entry: @entry, plugin: @plugin)
          @plugin1 = create(:plugin, name: 'activesupport')
          @plugin2 = create(:plugin, name: 'actionpack')
          @entry1 = create(:entry, plugin: @plugin1,
                                   title: 'activesupport(4.0.2)',
                                   major_version: 4,
                                   minor_version: 0,
                                   patch_version: 2
                    )
          @version1 = create(:version, installed: '4.0.2', project: @project, entry: @entry1, plugin: @plugin1)
          @entry2 = create(:entry, plugin: @plugin2,
                                   title: 'actionpack(4.0.2)',
                                   major_version: 4,
                                   minor_version: 0,
                                   patch_version: 2
                    )
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
          @entry = create(:entry, plugin: @plugin,
                                  major_version: 3,
                                  minor_version: 5,
                                  patch_version: 2
                          )
          @version = create(:version, installed: '3.5.2', project: @project, entry: @entry, plugin: @plugin)

          security_advisory_create(path, @plugin)
        end
        it '自身のProjectVersionを返却すること' do
          expect(@version.security_check).to eq [@version]
        end
      end

    end

    it_behaves_like 'display_version'
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
