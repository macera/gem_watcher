require 'rails_helper'

describe FeedsController do

  describe 'GET #index' do
    it "rails以外のすべてのfeedを配列で返却されること" do
      entry = create(:nokogiri_entry)
      rails_entry = create(:entry)
      get :index
      expect(assigns(:entries)).to eq [entry]
    end

    it "railsのfeedを配列で返却されること" do
      entry = create(:nokogiri_entry)
      rails_entry = create(:entry)
      get :index
      expect(assigns(:rails_entries)).to eq [rails_entry]
    end

    it "indexテンプレートが表示されること" do
      get :index
      expect(response).to render_template :index
    end
  end

end