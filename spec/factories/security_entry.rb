FactoryGirl.define do
  factory :security_entry do
    title     'セキュリティタイトル'
    content   'サマリー'
    author    '著者'
    url       'https://groups.google.com/d/topic/ruby-security-ann/xxx'
    published Time.now
    genre     0
    plugin    { create(:plugin) }
  end
end