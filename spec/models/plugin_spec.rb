require 'rails_helper'

RSpec.describe Plugin, type: :model do

  describe 'スコープ' do
    describe '.described' do
    end
  end

  describe 'クラスメソッド' do
    describe '.create_runtime_dependencies' do
      before do
        @plugin = create(:plugin, name: 'kaminari')
        @entry1 = create(:entry, plugin: @plugin,
                                major_version: 0,
                                minor_version: 16,
                                patch_version: '3'
        )
        @entry2 = create(:entry, plugin: @plugin,
                                major_version: 0,
                                minor_version: 16,
                                patch_version: '2'
        )
        allow(Gems).to receive(:dependencies).with(['kaminari']).and_return(
          [
            {:name=>"kaminari", :number=>"0.16.3", :platform=>"ruby", :dependencies=>[["actionpack", ">= 3.0.0"], ["activesupport", ">= 3.0.0"]]},
            {:name=>"kaminari", :number=>"0.16.2", :platform=>"ruby", :dependencies=>[["actionpack", ">= 3.0.0"], ["activesupport", ">= 3.0.0"]]}
          ]
        )
        #
        allow(Gems).to receive(:dependencies).with(['activesupport']).and_return(
          [
            {:name=>"activesupport", :number=>"4.2.7", :platform=>"ruby", :dependencies=>[]},
            {:name=>"activesupport", :number=>"4.2.6", :platform=>"ruby", :dependencies=>[]}
          ]
        )
        allow(Gems).to receive(:dependencies).with(['actionpack']).and_return(
          [
            {:name=>"activesupport", :number=>"4.2.7", :platform=>"ruby", :dependencies=>[]},
            {:name=>"activesupport", :number=>"4.2.6", :platform=>"ruby", :dependencies=>[]}
          ]
        )
        create(:plugin, name: 'activesupport')
        create(:plugin, name: 'actionpack')
      end
      it 'gemの依存gemが登録されること' do
        expect{ Plugin.create_runtime_dependencies }.to change{ Dependency.count }.by(4)
      end

      context '依存先が登録されていないgemの場合(現在では使われなくなった)' do
      end

    end
  end

  describe 'インスタンスメソッド' do
    describe '#get_gem_uri' do
      before do
        allow(Gems).to receive(:info).with('bundler').and_return(
            {
              "name" => "bundler",
              "homepage_uri" => "http://bundler.io",
              "source_code_uri" => "http://github.com/bundler/bundler/"
            }
          )
        allow(Gems).to receive(:info).with('nokogiri').and_return(
            {
              "name" => "nokogiri",
              "homepage_uri" => "http://nokogiri.org",
              "source_code_uri" => "https://github.com/sparklemotion/nokogiri"
            }
          )
        allow(Gems).to receive(:info).with('wkhtmltopdf').and_return(
            {
              "name" => "wkhtmltopdf",
              "homepage_uri" => nil,
              "source_code_uri" => nil
            }
          )
      end

      context 'パスがあり、末尾が/の場合' do
        it 'そのままのパスを返すこと' do
          plugin = create(:plugin, name: 'bundler')
          plugin.get_gem_uri
          expect(plugin.source_code_uri).to eq 'http://github.com/bundler/bundler/'
        end
      end
      context 'パスがあり、末尾が/で終っていない場合' do
        it '末尾に/を追加したパスを返すこと' do
          plugin = create(:plugin, name: 'nokogiri')
          plugin.get_gem_uri
          expect(plugin.source_code_uri).to eq 'https://github.com/sparklemotion/nokogiri/'
        end
      end
      context 'パスがない場合' do
        it 'nilを返すこと' do
          plugin = create(:plugin, name: 'wkhtmltopdf', source_code_uri: nil)
          plugin.get_gem_uri
          expect(plugin.source_code_uri).to eq nil
        end
      end
    end
  end

  describe 'コールバック' do
    describe '#create_created_table_log' do
    end
    describe '#create_updated_table_log' do
    end
    describe '#create_destroyed_table_log' do
    end
  end

end
