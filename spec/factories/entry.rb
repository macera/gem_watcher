FactoryGirl.define do

  factory :entry do
    title        "kaminari (0.17.0)"
    published    { Time.now }
    content      "\nKaminari is a Scope &amp;amp; Engine based"
    url          "https://rubygems.org/gems/kaminari/versions/0.17.0"
    author       "author name"
    plugin       { create(:plugin, name: 'kaminari') }
    # major_version 0
    # minor_version 17
    # patch_version 0
    # revision_version nil
  end

  factory :rails_entry, class: Entry do
    title        "rails (5.0.0)"
    published    { Time.now }
    content      "Ruby on Rails is a full-stack web framework"
    url          "https://rubygems.org/gems/rails/versions/5.0.0"
    author       "author name"
    plugin       { create(:plugin, name: 'rails') }
    # major_version 5
    # minor_version 0
    # patch_version 0
    # revision_version nil
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
    revision_version nil
  end

  factory :vulnerability_entry, class: Entry do
    title        "1.6.7"
    published    { Time.now }
    content      "Nokogiri (鋸) is an HTML, XML, SAX, and Reader parser."
    url          "https://rubygems.org/gems/nokogiri/versions/1.6.7"
    author       "author name"
    plugin       { create(:plugin, name: 'nokogiri') }
    major_version 1
    minor_version 6
    patch_version 7
    revision_version nil
  end
end
