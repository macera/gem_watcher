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
      # gem 'kaminari'
      # gem 'nokogiri', '1.6.8'
EOS

  end

  factory :project_gemfile_with_option_paths, class: Project do
    name              'project1'
    gitlab_id          1
    web_url            'http://test.com'
    http_url_to_repo   'http://test.git'
    ssh_url_to_repo    'git@test/test.git'
    gemfile_content     <<EOS
      source 'https://rubygems.org'
      gem 'rails', '4.2.6'
      # Use SCSS for stylesheets
      gem 'sass-rails', '~> 5.0'
      # Use Uglifier as compressor for JavaScript assets
      gem 'uglifier', '>= 1.3.0'
      # gem 'kaminari'
      # gem 'nokogiri', '1.6.8'
      gem 'test', path: "vendor/engines/test"
      gem 'prototype-rails', '4.0.1', git: 'git://github.com/rails/prototype-rails'
      gem 'activerecord-session_store', '0.1.1', github: 'rails/activerecord-session_store'
EOS
  end
end