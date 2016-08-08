require 'rails_helper'

# 参考: https://github.com/rubysec/bundler-audit/blob/master/spec/advisory_spec.rb

RSpec.describe SecurityAdvisory, type: :model do
  let(:root) { Rails.root.join('spec', 'fixtures') }
  let(:gem)  { 'actionpack' }
  let(:id)   { 'OSVDB-84243' }
  let(:path) { File.join(root,'gems',gem,"#{id}.yml") }
  let(:an_unaffected_version) do
    advisory = security_advisory_load(path)
    versions = Array(advisory.unaffected_versions.split(':')).map do |version|
      Gem::Requirement.new(*version.split(', '))
    end
    versions.map { |version_rule|
      # For all the rules, get the individual constraints out and see if we
      # can find a suitable one...
      version_rule.requirements.select { |(constraint, gem_version)|
        # We only want constraints where the version number specified is
        # one of the unaffected version.  I.E. we don't want ">", "<", or if
        # such a thing exists, "!=" constraints.
        ['~>', '>=', '=', '<='].include?(constraint)
      }.map { |(constraint, gem_version)|
        # Fetch just the version component, which is a Gem::Version,
        # and extract the string representation of the version.
        gem_version.version
      }
    }.flatten.first
  end

  describe 'クラスメソッド' do

    describe '.source_update' do
      context 'ruby-advisory-db リポジトリがない場合' do
        it 'ruby-advisory-db リポジトリを作成すること' do
          SecurityAdvisory.source_update
          expect(File.directory?(Settings.path.data_directory)).to be true
        end
      end
      context 'ruby-advisory-db リポジトリがある場合' do
        it 'git pull コマンドを実行すること' do
          expect_update_to_clone_data_repo!
          SecurityAdvisory.source_update
          expect(File.directory?(Settings.path.data_directory)).to be true

          expect_update_to_update_data_repo!
          SecurityAdvisory.source_update
          expect(File.directory?(Settings.path.data_directory)).to be true
        end
      end
    end

    describe '.all_update' do

    end

    describe '.load' do
      before do
        @plugin = create(:plugin, name: 'actionpack')
      end
      it 'SecurityAdvisoryが1件追加されること' do
        expect{ SecurityAdvisory.load(path, @plugin) }.to change{ SecurityAdvisory.count }.by(1)
      end
    end

    describe '.check_gem' do

    end

  end

  describe 'インスタンスメソッド' do

    describe '#title' do
      context 'cveが存在する場合' do
        let(:advisory) { create(:security_advisory, cve: '2015-1234', osvdb: 123456) }
        it 'nilを返却すること' do
          expect(advisory.title).to be == "CVE-#{advisory.cve}"
        end
      end
      context 'cveが存在しない場合' do
        let(:advisory) { create(:security_advisory, cve: nil, osvdb: 123456) }
        it 'nilを返却すること' do
          expect(advisory.title).to be == "OSVDB-#{advisory.osvdb}"
        end
      end
    end

    describe '#cve_id' do
      let(:advisory) { create(:security_advisory, cve: '2015-1234') }
      it 'CVE-で始まるIDを返却すること' do
        expect(advisory.cve_id).to be == "CVE-#{advisory.cve}"
      end
      context 'cveがnilの場合' do
        let(:advisory) { create(:security_advisory, cve: nil) }
        it 'nilを返却すること' do
          expect(advisory.cve_id).to be_nil
        end
      end
    end

    describe '#osvdb_id' do
      let(:advisory) { create(:security_advisory, osvdb: 123456) }
      it 'OSVDB-で始まるIDを返却すること' do
        expect(advisory.osvdb_id).to be == "OSVDB-#{advisory.osvdb}"
      end
      context 'osvdbがnilの場合' do
        let(:advisory) { create(:security_advisory, osvdb: nil) }
        it 'OSVDB-で始まるIDを返却すること' do
          expect(advisory.osvdb_id).to be_nil
        end
      end
    end

    describe '#unaffected_versions_list' do
      let(:advisory) do
        create(:security_advisory, unaffected_versions: "< 3.2.0:~> 3.2.0")
      end
      it '、区切りでunaffected_versionsを返却すること' do
        expect(advisory.unaffected_versions_list).to eq '< 3.2.0、~> 3.2.0'
      end
      context 'unaffected_versionsがnilの場合' do
        let(:advisory) do
          create(:security_advisory, unaffected_versions: nil)
        end
        it '空文字を返却すること' do
          expect(advisory.unaffected_versions_list).to eq ''
        end
      end
    end

    describe '#patched_versions_list' do
      let(:advisory) do
        create(:security_advisory, patched_versions: "~> 3.2.20:~> 4.0.11:~> 4.1.7:>= 4.2.0.beta3")
      end
      it '、区切りでpatched_versionsを返却すること' do
        expect(advisory.patched_versions_list).to eq "~> 3.2.20、~> 4.0.11、~> 4.1.7、>= 4.2.0.beta3"
      end
      context 'patched_versionsがnilの場合' do
        let(:advisory) do
          create(:security_advisory, patched_versions: nil)
        end
        it '空文字を返却すること' do
          expect(advisory.patched_versions_list).to eq ''
        end
      end
    end

    describe '#unaffected?' do
      subject { security_advisory_load(path) }
      context "影響のないバージョンに含む場合" do
        let(:version) { an_unaffected_version }

        it "trueを返却すること" do
          expect(subject.unaffected?(version)).to be true
        end
      end
      context "影響あるバージョンに含まない場合" do
        let(:version) { '3.0.9' }

        it "falseを返却すること" do
          expect(subject.unaffected?(version)).to be false
        end
      end
    end

    describe '#patched?' do
      subject { security_advisory_load(path) }
      context "修正バージョンに含む場合" do
        let(:version) { '3.1.11' }

        it "trueを返却すること" do
          expect(subject.patched?(version)).to be true
        end
      end

      context "修正バージョンに含まない場合" do
        let(:version) { '2.9.0' }

        it "falseを返却すること" do
          expect(subject.patched?(version)).to be false
        end
      end
    end

    describe '#vulnerable?' do
      subject { security_advisory_load(path) }
      context "修正バージョンに含む場合" do
        let(:version) { '3.1.11' }

        it "falseを返却すること" do
          expect(subject.vulnerable?(version)).to be false
        end
      end

      context "修正バージョンに含まない場合" do
        let(:version) { '2.9.0' }

        it "trueを返却すること" do
          expect(subject.vulnerable?(version)).to be true
        end
      end

      context "影響のないバージョンに含む場合" do
        let(:version) { an_unaffected_version }

        it "falseを返却すること" do
          expect(subject.vulnerable?(version)).to be false
        end
      end

      context "影響のないバージョンに含まない場合" do
        let(:version) { '1.2.3' }

        it "trueを返却すること" do
          expect(subject.vulnerable?(version)).to be true
        end
      end

    end

  end

  describe 'プライベートメソッド' do
    describe '#parse_versions' do
    end
  end

end