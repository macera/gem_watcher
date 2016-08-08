require 'rails_helper'

RSpec.describe FeedsHelper do

  describe '#new_label' do
    context '1週間前の場合' do
      it 'nilを返却すること' do
        expect(helper.new_label(1.weeks.ago)).to be nil
      end
    end
    context '1週間を超えない前の場合' do
      it 'nilを返却すること' do
        expect(helper.new_label(6.days.ago)).to eq "<span class=\"ui orange horizontal label\">New</span>"
      end
    end
  end

  describe '#show_more' do
    context '3以下' do
      it 'nilを返却すること' do
        expect(helper.show_more(3, 'test')).to be nil
      end
    end
    context '3以上' do
      it 'moreボタンを返却すること' do
        expect(helper.show_more(4, 'test')).to eq "<a class=\"item\" href=\"test\"><div class=\"ui small label\">...more</div></a>"
      end
    end
  end

end