FactoryGirl.define do
  factory :plugin do
    sequence :name do |n|
      "plugin-name#{n}"
    end
    newest          nil
    pre             nil
    source_code_uri 'http://github.com/plugin/plugin/'
  end
end