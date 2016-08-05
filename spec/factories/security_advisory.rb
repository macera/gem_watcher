FactoryGirl.define do
  factory :security_advisory do
    framework             nil
    cve                   '2013-4389'
    osvdb                 98629
    description           "Action Mailer Gem for Ruby contains a format string flaw in the Log Subscriber component."
    cvss_v2               "4.3"
    cvss_v3               nil
    date                  Date.new(2013, 8, 16)
    unaffected_versions   "~> 2.3.2"
    patched_versions      ">= 3.2.15"
    path                  Rails.root.join("/data/ruby-advisory-db/gems/actionmailer/OSVDB-98629.yml").to_s
    plugin                { create(:plugin) }
  end
end