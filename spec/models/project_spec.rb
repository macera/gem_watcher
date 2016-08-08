require 'rails_helper'

RSpec.describe Project, type: :model do

  let(:working_directory) { Rails.root.join(Settings.path.working_directory) }

  let(:rss) { File.read("spec/fixtures/rails_versions_atom_little.xml") } # 3件のentry
  let(:freedjira_parsed) { Feedjira::Parser::Atom.parse(rss) }
  let(:rss_path) { URI.join("#{Settings.feeds.rubygem}rails/versions.atom").to_s }
  #Feedjira::Parser::Atom.parse(File.read("spec/fixtures/rails_versions_atom.xml"))

  # describe 'クラスメソッド' do

  #   describe '.update_all' do
  #   end

  #   describe '.add_projects' do
  #   end

  # end

  describe 'インスタンスメソッド' do

    describe '#has_gemfile_in_remote?' do
      before do
        @project1 = create(:project, gitlab_id: 1)
        allow(@project1).to receive(:root_dirs).and_return([
          Gitlab::ObjectifiedHash.new(name: 'app'),
          Gitlab::ObjectifiedHash.new(name: 'Gemfile')
        ])
        @project2 = create(:project, gitlab_id: 1)
        allow(@project2).to receive(:root_dirs).and_return([
          Gitlab::ObjectifiedHash.new(name: 'app')
        ])
      end
      it 'リモートのprojectにGemfileがある場合trueを返すこと' do
        expect(@project1.has_gemfile_in_remote?).to be true
      end
      it 'リモートのprojectにGemfileがない場合falseを返すこと' do
        expect(@project2.has_gemfile_in_remote?).to be false
      end
    end

    # projectのディレクトリを作成
    describe '#generate_project_files' do
      before do
        @project = create(:project)
        allow(@project).to receive(:newest_gemfile).and_return(
          "source 'https://rubygems.org'\n\n\n# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'\ngem 'rails', '4.2.6'\ngem 'rails', '4.2.6'\n"
        )
      end
      context 'Gemfile.lockがある場合' do
        before do
          allow(@project).to receive(:root_dirs).and_return([
            Gitlab::ObjectifiedHash.new(name: 'app'),
            Gitlab::ObjectifiedHash.new(name: 'Gemfile'),
            Gitlab::ObjectifiedHash.new(name: 'Gemfile.lock'),
          ])
          allow(@project).to receive(:newest_gemfile_lock).and_return(
            "GEM\n  remote: https://rubygems.org/\n  specs:\nactionmailer (4.2.6)\nactionpack   (= 4.2.6)\n rails (4.2.6)\n"
          )
          @project.generate_project_files
        end
        it 'プロジェクト名のディレクトリを作成すること' do
          expect(File.directory?("#{Rails.root}/#{Settings.path.working_directory}/#{@project.name}")).to be true
        end
        it 'Gemfileを作成すること' do
          expect(File.exist?("#{Rails.root}/#{Settings.path.working_directory}/#{@project.name}/Gemfile")).to be true
        end
        it 'Gemfile.lockを作成すること' do
          expect(File.exist?("#{Rails.root}/#{Settings.path.working_directory}/#{@project.name}/Gemfile.lock")).to be true
        end
      end
      context 'Gemfile.lockがない場合' do
        before do
          allow(@project).to receive(:root_dirs).and_return([
            Gitlab::ObjectifiedHash.new(name: 'app'),
            Gitlab::ObjectifiedHash.new(name: 'Gemfile')
          ])
          @project.generate_project_files
        end
        it 'プロジェクト名のディレクトリを作成すること' do
          expect(File.directory?("#{Rails.root}/#{Settings.path.working_directory}/#{@project.name}")).to be true
        end
        it 'Gemfileを作成すること' do
          expect(File.exist?("#{Rails.root}/#{Settings.path.working_directory}/#{@project.name}/Gemfile")).to be true
        end
        it 'Gemfile.lockは作成しないこと' do
          expect(File.exist?("#{Rails.root}/#{Settings.path.working_directory}/#{@project.name}/Gemfile.lock")).to be false
        end
      end
    end

    describe '#update_gemfile' do
    end

    describe '#generate_gemfile_lock' do
    end

    describe '#create_plugins_and_versions' do
      before do
        @project1 = create(:project, gitlab_id: 1)
        @project_dir1 = working_directory.join(@project1.name)
        FileUtils.mkdir_p @project_dir1
        allow(@project1).to receive(:run).with("bundle list").and_return(
          "Gems included by the bundle:\n  * rails (4.2.6)\n"
        )
        #"Gems included by the bundle:\n  * rails (4.2.6)\n  * sass-rails (5.0.0)\n  * uglifier (1.3.0)\n"

        allow(Gems).to receive(:info).with('rails').and_return(
          {"name" => "rails"}
        )
        allow(Feedjira::Feed).to receive(:fetch_and_parse).with(rss_path).and_return(
          freedjira_parsed
        )
        #
      end
      after do
        FileUtils.rm_rf working_directory.join(@project1.name)
      end
      context 'Pluginテーブルに同じ名前のgemが保存されていない場合' do
        it 'pluginが作成されること' do
          expect{ @project1.create_plugins_and_versions }.to change{ Plugin.count }.by(1)
        end
        it 'entryが作成されること' do
          expect{ @project1.create_plugins_and_versions }.to change{ Entry.count }.by(3)
        end
        it 'project_versionが作成されること' do
          expect{ @project1.create_plugins_and_versions }.to change{ ProjectVersion.count }.by(1)
        end
      end
      context 'Pluginに同じ名前のgemが保存されている場合' do
        before do
          create(:plugin, name: 'rails')
          # create(:plugin, name: 'sass-rails')
          # create(:plugin, name: 'uglifier')
        end
        it 'pluginが作成されないこと' do
          expect{ @project1.create_plugins_and_versions }.to change{ Plugin.count }.by(0)
        end
        it 'project_versionが作成されること' do
          expect{ @project1.create_plugins_and_versions }.to change{ ProjectVersion.count }.by(1)
        end
      end
    end

    describe '#update_plugins_and_versions' do
      before do
        @project1 = create(:project, gitlab_id: 1,
          gemfile_content: <<EOS
            source 'https://rubygems.org'
            gem 'rails', '4.2.6'
            gem 'config'
            gem 'nokogiri'
EOS
        )
        @project_dir1 = working_directory.join(@project1.name)
        FileUtils.mkdir_p @project_dir1
        @rails_plugin = create(:plugin, name: 'rails')
        @rails_version = create(:version, installed: '4.2.5', newest: '4.2.6', plugin: @rails_plugin, project: @project1)
        @config_plugin = create(:plugin, name: 'config')
        @config_version = create(:version, installed: '1.2.1', newest: '1.2.1', requested: '=1.2.1', plugin: @config_plugin, project: @project1)
      end
      after do
        FileUtils.rm_rf working_directory.join(@project1.name)
      end

      context '以前と同じgemがある場合' do
        before do
          allow(@project1).to receive(:run).with("bundle list").and_return(
            "Gems included by the bundle:\n  * rails (4.2.6)\n  * config (1.2.1)\n"
          )
        end
        context 'バージョンが変更されている場合' do
          it 'installedが更新されること' do
            @project1.update_plugins_and_versions
            version = ProjectVersion.find(@rails_version.id)
            expect(version.installed).to eq '4.2.6'
          end
        end
        context 'バージョンが変更されていない場合' do
          it 'installedが同じままであること' do
            @project1.update_plugins_and_versions
            version = ProjectVersion.find(@config_version.id)
            expect(version.installed).to eq '1.2.1'
          end
        end
        it 'newest,requestedがnilになること' do
          @project1.update_plugins_and_versions
          version = ProjectVersion.find(@config_version.id)
          expect(version.newest).to eq nil
          expect(version.requested).to eq nil
        end
      end

      context 'gemが追加されている場合' do
        before do
          allow(@project1).to receive(:run).with("bundle list").and_return(
            "Gems included by the bundle:\n  * rails (4.2.6)\n  * config (1.2.1)\n  * nokogiri (1.6.8)\n"
          )
        end
        context 'Pluginテーブルに同じ名前のgemが保存されていない場合' do
          it 'pluginが作成されること' do
            expect{ @project1.update_plugins_and_versions }.to change{ Plugin.count }.by(1)
          end
          it 'project_versionが作成されること' do
            expect{ @project1.update_plugins_and_versions }.to change{ ProjectVersion.count }.by(1)
          end
        end
        context 'Pluginに同じ名前のgemが保存されている場合' do
          before do
            create(:plugin, name: 'nokogiri')
          end
          it 'pluginが作成されないこと' do
            expect{ @project1.update_plugins_and_versions }.to change{ Plugin.count }.by(0)
          end
          it 'project_versionが作成されること' do
            expect{ @project1.update_plugins_and_versions }.to change{ ProjectVersion.count }.by(1)
          end
        end
      end
      context '以前あったgemが削除されている場合' do
        before do
          allow(@project1).to receive(:run).with("bundle list").and_return(
            "Gems included by the bundle:\n  * rails (4.2.6)\n"
          )
        end
        context 'このpluginが他のprojectで使われている場合' do
          before do
            @project2 = create(:project)
            @config_version2 = create(:version, installed: '1.2.1', newest: '1.2.1', plugin: @config_plugin, project: @project2)
          end
          it 'project_versionが削除されること' do

            expect{ @project1.update_plugins_and_versions }.to change{ ProjectVersion.count }.by(-1)
          end
          it 'pluginは削除されないこと' do
            expect{ @project1.update_plugins_and_versions }.to change{ Plugin.count }.by(0)
          end
        end
        context 'このpluginが他のprojectで使われていない場合' do
          it 'project_versionが削除されること' do
            expect{ @project1.update_plugins_and_versions }.to change{ ProjectVersion.count }.by(-1)
          end
          it 'pluginが削除されること' do
            expect{ @project1.update_plugins_and_versions }.to change{ Plugin.count }.by(-1)
          end
        end
      end
    end

    describe '#update_versions' do
      before do
        @project1 = create(:project, gitlab_id: 1)
        @project_dir1 = working_directory.join(@project1.name)
        FileUtils.mkdir_p @project_dir1
        @rails_plugin = create(:plugin, name: 'rails')
        # create_、update_plugins_and_versions時にnewest等は初期化されている
        @rails_version = create(:version, installed: '4.2.5', newest: nil, plugin: @rails_plugin, project: @project1)
        @config_plugin = create(:plugin, name: 'config')
        @config_version = create(:version, installed: '1.2.1', plugin: @config_plugin, project: @project1)

        allow(@project1).to receive(:run).with("bundle outdated").and_return(
          "Fetching gem metadata from https://rubygems.org/\nFetching version metadata from https://rubygems.org/\nFetching dependency metadata from https://rubygems.org/\nResolving dependencies.........\n\nOutdated gems included in the bundle:\n  * rails (newest 4.2.6, installed 4.2.5)\n"
        )
      end
      after do
        FileUtils.rm_rf working_directory.join(@project1.name)
      end
      it 'コマンド結果に表示されたgemの場合project_versionが更新されること' do
        @project1.update_versions
        version = ProjectVersion.find(@rails_version.id)
        expect(version.newest).to eq '4.2.6'
      end
    end

    describe '#updated_gemfile?' do
      before do
        @project1 = create(:project,
          gitlab_id: 1,
          gemfile_content: "source 'https://rubygems.org'\n\n\n# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'\ngem 'rails', '4.2.5'\n"
        )
        allow(@project1).to receive(:root_dirs).and_return([
          Gitlab::ObjectifiedHash.new(name: 'app'),
          Gitlab::ObjectifiedHash.new(name: 'Gemfile')
        ])
        allow(@project1).to receive(:newest_gemfile).and_return(
          "source 'https://rubygems.org'\n\n\n# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'\ngem 'rails', '4.2.6'\ngem 'rails', '4.2.6'\n"
        )
        @project2 = create(:project,
          gitlab_id: 1,
          gemfile_content: "source 'https://rubygems.org'\n\n\n# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'\ngem 'rails', '4.2.6'\n"
        )
        allow(@project2).to receive(:root_dirs).and_return([
          Gitlab::ObjectifiedHash.new(name: 'app'),
          Gitlab::ObjectifiedHash.new(name: 'Gemfile')
        ])
        allow(@project2).to receive(:newest_gemfile).and_return(
          "source 'https://rubygems.org'\n\n\n# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'\ngem 'rails', '4.2.6'\n"
        )
        @project3 = create(:project, gitlab_id: 3)
        allow(@project3).to receive(:root_dirs).and_return([
          Gitlab::ObjectifiedHash.new(name: 'app')
        ])
      end
      it 'Gemfileがない場合、falseを返すこと' do
        expect(@project3.updated_gemfile?).to be false
      end
      it 'Gemfileが変更されていない場合、falseを返すこと' do
        expect(@project2.updated_gemfile?).to be false
      end
      it 'Gemfileが変更されていない場合、trueを返すこと' do
        expect(@project1.updated_gemfile?).to be true
      end
    end

    # API モック
    # describe '#newest_gemfile' do
    #   before do
    #   end
    #   context '正常系' do
    #     context 'Gemfileが存在する場合、Gemfileの内容を返却すること' do
    #     end
    #     context 'Gemfileが存在しない場合、nilを返却すること' do
    #     end
    #   end
    #   context '異常系' do
    #     it 'APIの返却値がエラーの場合、・・・・・' do
    #     end
    #   end
    # end

    describe '#gemfile_list' do
    end

    describe '#comment_gems_with_path_option' do
    end

    describe '#has_security_alert?' do
    end

    it_behaves_like 'display_version'

  end

  describe 'privateメソッド' do
    # API モック
    describe '#exist_file?' do
      before do
        @project1 = create(:project, gitlab_id: 1)
        allow(@project1).to receive(:root_dirs).and_return([
          Gitlab::ObjectifiedHash.new(name: 'app'),
          Gitlab::ObjectifiedHash.new(name: 'Gemfile')
        ])
      end
      it 'ファイルが存在する場合、trueが返却されること' do
        expect(@project1.send(:exist_file?, 'Gemfile')).to be true
      end
      it 'ファイルが存在しない場合、falseが返却されること' do
        expect(@project1.send(:exist_file?, 'Gemfile.lock')).to be false
      end
    end

  end

  describe 'コールバック' do
    describe '#create_created_table_log' do
    end
    describe '#create_updated_table_log' do
    end
  end

end
