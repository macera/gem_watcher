FactoryGirl.define do
  factory :entry do
    title        "v5.0.0.rc1"
    published    { Time.now }
    content      "<p>v5.0.0 release</p>"
    url          "http://github.com/plugin/plugin/releases/tag/v5.0.0"
    author       "author name"
    plugin       { create(:plugin) }
  end
end
