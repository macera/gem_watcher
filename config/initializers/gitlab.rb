# config/initializers/gitlab.rb
Gitlab.configure do |config|
  config.endpoint       = Settings.gitlab.endpoint # API endpoint URL, default: ENV['GITLAB_API_ENDPOINT']
  config.private_token  = Settings.gitlab.private_token                     # user's private token or OAuth2 access token, default: ENV['GITLAB_API_PRIVATE_TOKEN']
  # Optional
  # config.user_agent   = 'Custom User Agent'          # user agent, default: 'Gitlab Ruby Gem [version]'
  config.sudo         = Settings.gitlab.sudo           # username for sudo mode, default: nil
end