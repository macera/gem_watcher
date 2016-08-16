require 'rails_helper'

describe AboutsController do

  describe 'GET #index' do
    it "indexテンプレートが表示されること" do
      get :index
      expect(response).to render_template :index
    end
  end

end