FactoryGirl.define do
  factory :entry do
    title        "v5.0.0.rc1"
    published    { Time.now }
    content      "<p>v5.0.0 release</p>"
    url          "http://github.com/plugin/plugin/releases/tag/v5.0.0"
    author       "author name"
    plugin       { create(:plugin, name: 'rails') }
  end

  factory :nokogiri_entry, class: Entry do
    title        "1.6.8"
    published    { Time.now }
    content      "Nokogiri (鋸) is an HTML, XML, SAX, and Reader parser.  Among
Nokogiri&amp;#39;s many features is the ability to search documents via XPath
or CSS3 selectors."
    url          "https://rubygems.org/gems/nokogiri/versions/1.6.8"
    author       "author name"
    plugin       { create(:plugin, name: 'nokogiri') }
  end
end
