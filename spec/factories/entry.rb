FactoryGirl.define do
  factory :entry do
    title        "rails (5.0.0)"
    published    { Time.now }
    content      "Ruby on Rails is a full-stack web framework"
    url          "https://rubygems.org/gems/rails/versions/5.0.0"
    author       "author name"
    plugin       { create(:plugin, name: 'rails') }
    major_version 5
    minor_version 0
    patch_version 0
  end

  factory :rails_entry, class: Entry do

  end

  factory :nokogiri_entry, class: Entry do
    title        "1.6.8"
    published    { Time.now }
    content      "Nokogiri (鋸) is an HTML, XML, SAX, and Reader parser."
    url          "https://rubygems.org/gems/nokogiri/versions/1.6.8"
    author       "author name"
    plugin       { create(:plugin, name: 'nokogiri') }
    major_version 1
    minor_version 6
    patch_version 8
  end
end
