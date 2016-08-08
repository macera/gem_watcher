require 'rails_helper'

describe VersionsController do

  describe 'GET #index' do
    before do
      @plugin = create(:plugin)
      @entry = create(:entry, plugin: @plugin)
      @version = create(:version, plugin: @plugin, entry: @entry)
    end
    it "すべてのプロジェクトを配列で返却されること" do
      get :index, params: { plugin_id: @plugin.id }
      expect(assigns(:entries)).to eq [@entry]
    end

    it "indexテンプレートが表示されること" do
      get :index, params: { plugin_id: @plugin.id }
      expect(response).to render_template :index
    end
  end

  describe 'GET #show' do
    before do
      @plugin = create(:plugin)
      @entry = create(:entry, plugin: @plugin)
      @version = create(:version, plugin: @plugin, entry: @entry)
    end
    it "showテンプレートが表示されること" do
      get :show, params: { plugin_id: @plugin.id, id: @entry.id }
      expect(response).to render_template :show
    end

    context '対象のplugin idが存在しない場合' do
      it 'トップにリダイレクトすること' do
        get :show, params: { plugin_id: 0, id: 0 }
        expect(response).to redirect_to root_path
      end
    end
    context '対象のversion idが存在しない場合' do
      it '一覧にリダイレクトすること' do
        get :show, params: { plugin_id: @plugin.id, id: 0 }
        expect(response).to redirect_to plugin_versions_path(plugin_id: @plugin.id)
      end
    end
  end

end