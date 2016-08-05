require 'rails_helper'

RSpec.describe ProjectVersion, type: :model do

  describe 'スコープ' do
    before do
      project1 = create(:project)
      @version1 = create(:version, installed: '4.0.0', newest: '5.0.0', project: project1)
      @version2 = create(:version, installed: '4.0.0', newest: nil, project: project1)
      @version3 = create(:version, installed: '4.2.0', newest: '5.0.0', project: project1)
    end

    describe '.newest_versions' do
      it '最新に更新可能なversionのみ取得できること' do
        expect(ProjectVersion.newest_versions).to eq [@version1, @version3]
      end
    end

    describe '.updated_versions' do
      it '最新に更新済みなversionのみ取得できること' do
        expect(ProjectVersion.updated_versions).to eq [@version2]
      end
    end
    describe '.only_gemfile' do
    end
    describe '.no_gemfile' do
    end
  end

  describe 'インスタンスメソッド' do
    describe '#security_check' do
    end
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
