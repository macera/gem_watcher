require 'rails_helper'

RSpec.describe Plugin, type: :model do

  describe 'スコープ' do
    describe '.described' do
      before do
        @plugin1 = create(:plugin)
        create(:version, plugin: @plugin1, described: true)

        @plugin2 = create(:plugin)
        create(:version, plugin: @plugin2, described: true)
        create(:version, plugin: @plugin2, described: false)

        @plugin3 = create(:plugin)
        create(:version, plugin: @plugin3, described: false)
      end
      it '1回以上Gemfileに書かれたことがあるgemのみ返却すること' do
        expect(Plugin.described).to eq [@plugin1, @plugin2]
      end

    end
  end

  describe 'クラスメソッド' do
    describe '.create_runtime_dependencies' do
      context '依存先が登録されているgemの場合' do
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
      end

      context '依存先が登録されていないgemの場合(現在では使われなくなった)' do
        before do
          @plugin = create(:plugin, name: 'nokogiri')
          @entry1 = create(:entry, plugin: @plugin,
                                  major_version: 1,
                                  minor_version: 6,
                                  patch_version: '6.4'
          )
          @entry2 = create(:entry, plugin: @plugin,
                                  major_version: 1,
                                  minor_version: 6,
                                  patch_version: '8'
          )
          allow(Gems).to receive(:dependencies).with(['nokogiri']).and_return(
            [
              {:name=>"nokogiri", :number=>"1.6.6.4", :platform=>"ruby", :dependencies=>[["mini_portile", "~> 0.6.0"]]},
              {:name=>"nokogiri", :number=>"1.6.8", :platform=>"ruby", :dependencies=>[["pkg-config", "~> 1.1.7"], ["mini_portile2", "~> 2.1.0"]]},
            ]
          )
        end
        it 'gemの依存gemが登録されること' do
          expect{ Plugin.create_runtime_dependencies }.to change{ Dependency.count }.by(3)
        end
        it '依存先のpluginが存在しないgemを登録すること' do
          Plugin.create_runtime_dependencies
          expect(@entry1.dependencies.first.plugin).to be nil
        end
        it 'provisional_nameを登録すること' do
          Plugin.create_runtime_dependencies
          expect(@entry1.dependencies.first.provisional_name).to eq 'mini_portile'
        end

      end

      context 'すでに依存情報が登録されている場合' do
        before do
          @plugin1 = create(:plugin, name: 'nokogiri')
          @plugin2 = create(:plugin, name: 'pkg-config')
          @plugin3 = create(:plugin, name: 'mini_portile2')
          @entry1 = create(:entry, plugin: @plugin1,
                                  major_version: 1,
                                  minor_version: 6,
                                  patch_version: '6.4'
          )
          @entry2 = create(:entry, plugin: @plugin1,
                                  major_version: 1,
                                  minor_version: 6,
                                  patch_version: '8'
          )
          @dependency1 = create(:dependency,
            entry: @entry1,
            provisional_name: 'mini_portile',
            requirements:     '~> 0.6.0',
            plugin:           nil)
          @dependency2 = create(:dependency,
            entry: @entry2,
            provisional_name: nil,
            requirements:     '~> 1.1.7',
            plugin: @plugin2)
          create(:dependency,
            entry: @entry2,
            provisional_name: nil,
            requirements:     '~> 2.1.0',
            plugin: @plugin3)

          allow(Gems).to receive(:dependencies).with(['nokogiri']).and_return(
            [
              {:name=>"nokogiri", :number=>"1.6.6.4", :platform=>"ruby", :dependencies=>[["mini_portile", "~> 0.6.0"]]},
              {:name=>"nokogiri", :number=>"1.6.8", :platform=>"ruby", :dependencies=>[["pkg-config", "~> 1.1.7"], ["mini_portile2", "~> 2.1.0"]]},
            ]
          )
          allow(Gems).to receive(:dependencies).with(['pkg-config']).and_return(
            [
              {:name=>"pkg-config", :number=>"1.1.7", :platform=>"ruby", :dependencies=>[]},
            ]
          )
          allow(Gems).to receive(:dependencies).with(['mini_portile2']).and_return(
            [
              {:name=>"mini_portile2", :number=>"2.1.0", :platform=>"ruby", :dependencies=>[]},
            ]
          )
          allow(Gems).to receive(:dependencies).with(['mini_portile']).and_return(
            [
              {:name=>"mini_portile", :number=>"0.6.0", :platform=>"ruby", :dependencies=>[]},
            ]
          )
        end
        it 'gemの依存gemが登録されないこと' do
          expect{ Plugin.create_runtime_dependencies }.to change{ Dependency.count }.by(0)
        end
        context '存在しなかったpluginが後から登録された場合' do
          before do
            @plugin4 = create(:plugin, name: 'mini_portile')
          end
          it 'plugin_idで更新すること' do
            Plugin.create_runtime_dependencies
            expect(Dependency.find(@dependency1.id).plugin_id).to eq @plugin4.id
          end
        end
        context 'pluginを後から削除した場合' do
          before do
            Plugin.find_by(name: 'pkg-config').destroy
          end
          it 'dependencyも削除すること' do
            expect(Dependency.find_by(plugin: @plugin2)).to be nil
          end
          it 'provisional_nameで再び登録すること' do
            Plugin.create_runtime_dependencies
            expect(Dependency.where(provisional_name: 'pkg-config', entry: @entry2, plugin: nil).first).not_to be nil
          end
        end
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
