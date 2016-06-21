FactoryGirl.define do
  factory :plugin do
    name            'plugin-name'
    newest          nil
    pre             nil
    source_code_uri 'http://github.com/plugin/plugin/'
  end
end