FactoryGirl.define do
  factory :project do
    name              'project1'
    gitlab_id          1
    web_url            'http://test.com'
    http_url_to_repo   'http://test.git'
    ssh_url_to_repo    'git@test/test.git'
  end
end