require 'rails_helper'

RSpec.describe Project, type: :model do

  let(:working_directory) { Rails.root.join(Settings.path.working_directory) }

  describe 'クラスメソッド' do

    describe '.update_all' do

      context 'Gemfileが更新されている場合' do
        it 'update_gemfileメソッドが呼ばれること' do
        end
        it 'generate_gemfile_lockメソッドが呼ばれること' do
        end
        it 'update_plugins_and_versionsメソッドが呼ばれること' do
        end
        it 'update_versionsメソッドが呼ばれること' do
        end
      end

      context 'Gemfileが更新されていない場合' do
        it 'update_gemfileメソッドが呼ばれないこと' do
        end
        it 'generate_gemfile_lockメソッドが呼ばれないこと' do
        end
        it 'update_plugins_and_versionsメソッドが呼ばれないこと' do
        end
        it 'update_versionsメソッドが呼ばれないこと' do
        end
      end

    end

    describe '.add_projects' do

      it 'generate_project_filesメソッドが呼ばれること' do
      end

      context 'sortオプションがある場合' do
        it 'GitLabのプロジェクトがsortされること' do
        end
      end
      context 'sortオプションがない場合' do
        it 'GitLabのプロジェクトがsortされないこと' do
        end
      end

      context 'Gemfileがあるプロジェクトの場合' do
        it 'generate_gemfile_lockメソッドが呼ばれること' do
        end
        it 'create_plugins_and_versionsメソッドが呼ばれること' do
        end
        it 'create_plugins_and_versionsメソッドが呼ばれること' do
        end
      end

      context 'Gemfileがあるプロジェクトの場合' do
        it 'generate_gemfile_lockメソッドが呼ばれないこと' do
        end
        it 'create_plugins_and_versionsメソッドが呼ばれないこと' do
        end
        it 'create_plugins_and_versionsメソッドが呼ばれないこと' do
        end
      end

    end
  end

  describe 'インスタンスメソッド' do
    # describe '#has_gemfile?' do
    #   before do
    #     @project1 = create(:project, name: 'project1')
    #     @project_dir1 = working_directory.join(@project1.name)
    #     FileUtils.mkdir_p @project_dir1
    #     FileUtils.touch @project_dir1.join('Gemfile')
    #     @project2 = create(:project, name: 'project2')
    #     @project_dir2 = working_directory.join(@project2.name)
    #     FileUtils.mkdir_p @project_dir2
    #   end
    #   after do
    #     FileUtils.rm_rf @project_dir1
    #     FileUtils.rm_rf @project_dir2
    #   end
    #   it 'Gemfileがある場合trueを返すこと' do
    #     expect(@project1.has_gemfile?).to be true
    #   end
    #   it 'Gemfileがない場合falseを返すこと' do
    #     expect(@project2.has_gemfile?).to be false
    #   end
    # end

    # API モック
    describe '#has_gemfile_in_remote?' do
      context '正常系' do
        it 'リモートのprojectにGemfileがある場合trueを返すこと' do
        end
        it 'リモートのprojectにGemfileがない場合falseを返すこと' do
        end
      end
      context '異常系' do
        it 'APIの返却値がエラーの場合、・・・・・' do
        end
      end
    end

    # API モック
    describe '#newest_gemfile' do
      context '正常系' do
        context 'Gemfileが存在する場合、Gemfileの内容を返却すること' do
        end
        context 'Gemfileが存在しない場合、nilを返却すること' do
        end
      end
      context '異常系' do
        it 'APIの返却値がエラーの場合、・・・・・' do
        end
      end
    end

    # API モック
    describe '#generate_project_files' do
      context '正常系' do
        it 'projectのディレクトリを作成すること' do
        end
      end
      context '異常系' do
        context 'すでにprojectが存在する場合' do
          it 'エラーメッセージログを表示すること' do
          end
        end
        context 'コマンドの返却値がエラーの場合' do
          it 'エラーメッセージログを表示すること' do
          end
        end
      end
    end

    # API モック
    describe '#generate_gemfile_lock' do
      context '正常系' do
        it '(コマンドが正しく実行されること)' do
        end
        context 'Gemfile.lockがないプロジェクトの場合' do
          it 'Gemfile.lockが作成されること' do
          end
        end
      end
      context '異常系' do
        context 'コマンドの返却値がエラーの場合' do
          it 'エラーメッセージログを表示すること' do
          end
        end
      end
    end

    # API モック
    describe '#create_plugins_and_versions' do
      context '正常系' do
        it '(コマンドが正しく実行されること)' do
        end
        context 'Pluginテーブルに同じ名前のgemが保存されていない場合' do
          it 'pluginが作成されること' do
          end
          it 'project_versionが作成されること' do
          end
        end
        context 'Pluginに同じ名前のgemが保存されている場合' do
          it 'pluginが作成されないこと' do
          end
          it 'project_versionが作成されること' do
          end
        end
      end
      context '異常系' do
        it 'コマンドの返却値がエラーの場合、・・・・・' do
        end
      end
    end

    # API モック
    describe '#update_plugins_and_versions' do
      context '正常系' do
        it '(コマンドが正しく実行されること)' do
        end

        context '以前と同じgemがある場合' do
          context 'バージョンが変更されている場合'
            it 'installedが更新されること' do
            end
          end
          context 'バージョンが変更されていない場合'
            it 'installedが同じままであること' do
            end
          end
          it 'newest,requestがnilになること' do
          end
        end

        context 'gemが追加されている場合'
          context 'Pluginテーブルに同じ名前のgemが保存されていない場合' do
            it 'pluginが作成されること' do
            end
            it 'project_versionが作成されること' do
            end
          end
          context 'Pluginに同じ名前のgemが保存されている場合' do
            it 'pluginが作成されないこと' do
            end
            it 'project_versionが作成されること' do
            end
          end
        end
        context '以前あったgemが削除されている場合'
          context 'このpluginが他のprojectで使われている場合' do
            it 'project_versionが削除されること' do
            end
            it 'pluginは削除されないこと' do
            end
          end
          context 'このpluginが他のprojectで使われていない場合' do
            it 'project_versionが削除されること' do
            end
            it 'pluginが削除されること' do
            end
          end
        end
      end
      context '異常系' do
        it 'コマンドの返却値がエラーの場合、・・・・・' do
        end
      end
    end

    # API モック
    describe '#update_versions' do
      context '正常系' do
        it 'コマンド結果に表示されたgemの場合project_versionが更新されること' do
        end
      end
      context '異常系' do
        it 'コマンドの返却値がエラーの場合、・・・・・' do
        end
      end
    end

    describe '#updated_gemfile?' do
      context '正常系' do
        it 'Gemfileがない場合、falseを返すこと' do
        end
        # API モック
        it 'Gemfileが変更されていない場合、falseを返すこと' do
        end
        it 'Gemfileが変更されていない場合、trueを返すこと' do
        end
      end
      context '異常系' do
        it 'APIの返却値がエラーの場合、・・・・・' do
        end
      end
    end
  end

  describe 'privateメソッド' do
    # API モック
    describe '#exist_file?' do
      context '正常系' do
        it 'ファイルが存在する場合、trueが返却されること' do
        end
        it 'ファイルが存在しない場合、falseが返却されること' do
        end
      end
      context '異常系' do
        it 'APIの返却値がエラーの場合、・・・・・' do
        end
      end

    end

    # describe '#production?' do
    # end

  end

end
