require 'rails_helper'

describe FeedsController do

  describe 'GET #index' do

    before do
      plugin1 = create(:plugin)
      create(:version, plugin: plugin1)
      @entry = create(:entry, plugin: plugin1)

      plugin2 = create(:plugin, name: 'rails')
      create(:version, plugin: plugin2)
      @rails_entry = create(:rails_entry, plugin: plugin2)
    end

    it "rails以外のすべてのfeedを配列で返却されること" do
      get :index
      expect(assigns(:entries)).to eq [@entry]
    end

    it "railsのfeedを配列で返却されること" do
      get :index
      expect(assigns(:rails_entries)).to eq [@rails_entry]
    end

    it "indexテンプレートが表示されること" do
      get :index
      expect(response).to render_template :index
    end

    context '脆弱性のあるgemを持つプロジェクトがある場合' do
      before do
        project = create(:project)
        plugin  = create(:plugin, name: 'nokogiri')
        entry = create(:vulnerability_entry, plugin: plugin)
        version = create(:vulnerability_version, project: project, plugin: plugin, entry: entry)
        create(:security_advisory, plugin: plugin)
      end
      it "flash[:alert]にメッセージが含まれること" do
        get :index
        expect(flash[:alert]).to be_present
      end
    end
  end

end