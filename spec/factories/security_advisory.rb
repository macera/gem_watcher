FactoryGirl.define do
  factory :security_advisory do
    framework             nil
    cve                   'CVE-2015-8806 '
    osvdb                 98629
    description           "Nokogiri is affected by series of vulnerabilities in libxml2 and libxslt"
    cvss_v2               nil
    cvss_v3               nil
    date                  Date.new(2016, 6, 7)
    unaffected_versions   "< 1.6.0"
    patched_versions      ">= 1.6.8"
    path                  Rails.root.join("/data/ruby-advisory-db/gems/actionmailer/OSVDB-98629.yml").to_s
    plugin                { create(:plugin) }

    after(:create) do |advisory|
      advisory.plugin.entries.each do |entry|
        if advisory.vulnerable?(entry.version)
          create(:vulnerable_entry, entry: entry, security_advisory: advisory)
        end
      end
    end
  end
end