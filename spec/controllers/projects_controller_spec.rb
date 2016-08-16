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

    describe 'gem検索' do
      before do
        @project = create(:project)
        @plugin1 = create(:plugin)
        entry1 = create(:entry, plugin: @plugin1)
        @version1 = create(:version, plugin: @plugin1, entry: entry1, project: @project, newest: '4.2.0')
        @plugin2 = create(:plugin)
        entry2 = create(:entry, plugin: @plugin2)
        @version2 = create(:version, plugin: @plugin2, entry: entry2, project: @project, newest: nil)
      end
      context 'nameでgem検索する場合' do
        it "指定のバージョンが返却されること" do
          get :show, params: { id: @project.id, plugin_form: { name: @plugin1.name } }
          expect(assigns(:plugins)).to eq [@version1]
        end
      end
      context 'updatedでgem検索する場合' do
        it "更新可能なバージョンが返却されること" do
          get :show, params: { id: @project.id, plugin_form: { updated: '1' } }
          expect(assigns(:plugins)).to eq [@version1]
        end
        it "更新済みバージョンが返却されること" do
          get :show, params: { id: @project.id, plugin_form: { updated: '2' } }
          expect(assigns(:plugins)).to eq [@version2]
        end
        it "全てのバージョンが返却されること" do
          get :show, params: { id: @project.id, plugin_form: { updated: '0' } }
          expect(assigns(:plugins)).to eq [@version1, @version2]
        end
      end
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