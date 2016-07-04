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

  describe 'GET #show' do
    it "指定のプロジェクトが返却されること" do
      entry = create(:entry)
      get :show, id: entry.id
      expect(assigns(:entry)).to eq entry
    end

    it "showテンプレートが表示されること" do
      entry = create(:entry)
      get :show, id: entry.id
      expect(response).to render_template :show
    end
  end
end