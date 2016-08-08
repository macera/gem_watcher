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
      get :show, params: { id: project.id }
      expect(assigns(:project)).to eq project
    end

    it "showテンプレートが表示されること" do
      project = create(:project)
      get :show, params: { id: project.id }
      expect(response).to render_template :show
    end
  end

  context 'gemfileが存在しない場合' do
    describe 'GET #edit' do
      it "指定のプロジェクトが返却されること" do
        project = create(:project, gemfile_content: nil)
        get :edit, params: { id: project.id }
        expect(assigns(:project)).to eq project
      end
      it "editテンプレートを表示すること" do
        project = create(:project, gemfile_content: nil)
        get :edit, params: { id: project.id }
        expect(response).to render_template :edit
      end
    end

    describe 'PATCH #update' do
      before do
        @project = create(:project, gemfile_content: nil)
      end
      context "有効な属性の場合" do
        it "要求された@projectを取得すること" do
          patch :update, params: { id: @project, project: attributes_for(:project) }
          expect(assigns(:project)).to eq(@project)
        end
        it "ProjectVersionを追加すること" do
          params = { project_versions_attributes: [ attributes_for(:project_version_attributes)   ] }
          expect {
            patch :update,
            params: {
              id:      @project,
              project: attributes_for(:project).merge(params)
            }
          }.to change(ProjectVersion, :count).by(1)
        end
        it "詳細画面にリダイレクトすること" do
          patch :update, params: { id: @project, project: attributes_for(:project) }
          expect(response).to redirect_to project_path(assigns[:project])
        end
      end

      context "無効な属性の場合" do
        let(:attributes) {
          { project_versions_attributes: [
              {
                plugin_name: '',
                installed:   '2.3.5',
                requested:   ''
              }
            ]
          }
        }
        it "ProjectVersionを追加しないこと" do
          params =
          expect {
            patch :update,
            params: {
              id:      @project,
              project: attributes_for(:project).merge(attributes)
            }
          }.to change(ProjectVersion, :count).by(0)
        end
        it "編集画面を再描画すること" do
          patch :update, params: {
            id: @project, project: attributes_for(:project).merge(attributes)
          }
          expect(response).to render_template :edit
        end
      end

    end

  end

  context 'gemfileが存在する場合' do
    describe 'GET #edit' do
      it "詳細画面にリダイレクトすること" do
        project = create(:project)
        get :edit, params: { id: project.id }
        expect(response).to redirect_to project_path(assigns[:project])
      end
    end
    describe 'PATCH #update' do
      it "詳細画面にリダイレクトすること" do
        @project = create(:project, gemfile_content: nil)
        patch :update, params: { id: @project, project: attributes_for(:project) }
        expect(response).to redirect_to project_path(assigns[:project])
      end
    end
  end

end