require 'rails_helper'

describe PluginsController do

  describe 'GET #show' do
    it "指定のgemが返却されること" do
      plugin = create(:plugin)
      get :show, params: { id: plugin.id }
      expect(assigns(:plugin)).to eq plugin
    end

    it "showテンプレートが表示されること" do
      plugin = create(:plugin)
      get :show, params: { id: plugin.id }
      expect(response).to render_template :show
    end
  end
end