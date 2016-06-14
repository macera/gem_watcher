require 'rails_helper'

RSpec.describe Plugin, type: :model do

  describe 'プライベートメソッド' do
    describe '#add_source_code_uri_to_trailing_slash' do
      before do
        allow(Gems).to receive(:info).with('bundler').and_return(
            {
              "name" => "bundler",
              "homepage_uri" => "http://bundler.io",
              "source_code_uri" => "http://github.com/bundler/bundler/"
            }
          )
        allow(Gems).to receive(:info).with('nokogiri').and_return(
            {
              "name" => "nokogiri",
              "homepage_uri" => "http://nokogiri.org",
              "source_code_uri" => "https://github.com/sparklemotion/nokogiri"
            }
          )
        allow(Gems).to receive(:info).with('wkhtmltopdf').and_return(
            {
              "name" => "wkhtmltopdf",
              "homepage_uri" => nil,
              "source_code_uri" => nil
            }
          )
      end
      context 'パスがあり、末尾が/の場合' do
        it 'そのままのパスを返すこと' do
          plugin = create(:plugin, name: 'bundler')
          expect(plugin.send(:add_source_code_uri_to_trailing_slash)).to eq 'http://github.com/bundler/bundler/'
        end
      end
      context 'パスがあり、末尾が/で終っていない場合' do
        it '末尾に/を追加したパスを返すこと' do
          plugin = create(:plugin, name: 'nokogiri')
          expect(plugin.send(:add_source_code_uri_to_trailing_slash)).to eq 'https://github.com/sparklemotion/nokogiri/'
        end
      end
      context 'パスがない場合' do
        it 'nilを返すこと' do
          plugin = create(:plugin, name: 'wkhtmltopdf')
          expect(plugin.send(:add_source_code_uri_to_trailing_slash)).to eq nil
        end
      end
    end
  end

end
