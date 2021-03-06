require 'rails_helper'

RSpec.describe Dependency, type: :model do
  describe '#alert_status' do
    before do
      # config 1.2.1
      @plugin1 = create(:plugin, name: 'rails')
      @entry1 = create(:entry, plugin: @plugin1, title: 'rails (5.0.0)')
      @plugin2 = create(:plugin, name: 'activesupport')
      @entry_p2 = create(:entry, plugin: @plugin2, title: 'activesupport (5.0.0)')
      @dependency1 = create(:dependency,
                                entry: @entry1,
                                provisional_name: nil,
                                requirements:     '= 5.0.0',
                                plugin: @plugin2
                            )

      @plugin3 = create(:plugin, name: 'i18n')
      @entry_p3 = create(:entry, plugin: @plugin3, title: 'i18n (0.7.0)')
      @dependency2 = create(:dependency,
                                entry: @entry_p2,
                                provisional_name: nil,
                                requirements:     '~> 0.7',
                                plugin: @plugin3
                            )
    end
    context '自身のgemに脆弱性がある場合' do
      before do
        advisory = create(:security_advisory, plugin: @plugin2, patched_versions: ">= 5.0.0.1", unaffected_versions: nil)
      end
      it 'redを返却すること' do
        expect(@dependency1.alert_status).to eq 'red'
      end
    end
    context '自身のgemのdependency gemに脆弱性がある場合' do
      before do
        advisory = create(:security_advisory, plugin: @plugin3, patched_versions: ">= 1.0", unaffected_versions: nil)
      end
      it 'yellowを返却すること' do
        expect(@dependency1.alert_status).to eq 'yellow'
      end
    end
    context '自身のgemに脆弱性がない場合' do
      it '空文字を返却すること' do
        expect(@dependency1.alert_status).to eq ''
      end
    end
  end

  describe '#latest_version_in_requirements' do
    before do
      # config 1.2.1
      @plugin1 = create(:plugin, name: 'config')
      @entry1 = create(:entry, plugin: @plugin1, title: 'config (1.2.1)')
    end
    context 'pluginがある場合' do
      before do
        @plugin2 = create(:plugin, name: 'deep_merge')
        @entry_p2_1 = create(:entry, plugin: @plugin2, title: 'deep_merge (1.1.0)')
        @entry_p2_2 = create(:entry, plugin: @plugin2, title: 'deep_merge (1.1.1)')
        @entry_p2_3 = create(:entry, plugin: @plugin2, title: 'deep_merge (2.0.0)')
        @dependency1 = create(:dependency,
          entry: @entry1,
          provisional_name: nil,
          requirements:     '>= 1.0.1, ~> 1.0',
          plugin: @plugin2)
      end
      it 'requirements中の最新のversionを取得すること' do
        expect(@dependency1.latest_version_in_requirements).to eq @entry_p2_2
      end
    end
    context 'pluginがない場合' do
      before do
        @dependency1 = create(:dependency,
          entry: @entry1,
          provisional_name: 'plugin name',
          requirements:     '>= 1.0.1, ~> 1.0',
          plugin: nil)
      end
      it 'nilを返却すること' do
        expect(@dependency1.latest_version_in_requirements).to eq nil
      end
    end
  end


end