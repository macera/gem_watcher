FactoryGirl.define do
  factory :project do
    name              'project1'
    gitlab_id          1
    web_url            'http://test.com'
    http_url_to_repo   'http://test.git'
    ssh_url_to_repo    'git@test/test.git'
    gemfile_content     <<EOS
      source 'https://rubygems.org'
      # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
      gem 'rails', '4.2.6'
      # Use SCSS for stylesheets
      gem 'sass-rails', '~> 5.0'
      # Use Uglifier as compressor for JavaScript assets
      gem 'uglifier', '>= 1.3.0'
EOS

  end
end