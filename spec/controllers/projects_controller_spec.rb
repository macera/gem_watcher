require 'rails_helper'

describe ProjectsController do

  describe 'GET #index' do
    it "すべてのプロジェクトを配列で返却されること" do
      project = create(:project)
      get :index
      expect(assigns(:projects)).to eq [project]
    end

    it "indexテンプレートが表示されること" do
      get :index
      expect(response).to render_template :index
    end
  end

  describe 'GET #show' do
    it "指定のプロジェクトが返却されること" do
      project = create(:project)
      get :show, id: project.id
      expect(assigns(:project)).to eq project
    end

    it "showテンプレートが表示されること" do
      project = create(:project)
      get :show, id: project.id
      expect(response).to render_template :show
    end
  end
end