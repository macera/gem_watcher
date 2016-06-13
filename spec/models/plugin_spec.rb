require 'rails_helper'

RSpec.describe Plugin, type: :model do

  describe 'プライベートメソッド' do
    describe '#add_source_code_uri_to_trailing_slash' do

      context 'パスがあり、末尾が/の場合' do
        it 'そのままのパスを返すこと' do
        end
      end
      context 'パスがあり、末尾が/で終っていない場合' do
        it '末尾に/を追加したパスを返すこと' do
        end
      end
      context 'パスがない場合' do
        it 'nilを返すこと' do
        end
      end
    end
  end

end
