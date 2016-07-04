Rails.application.routes.draw do

  root 'feeds#index'

  resources :feeds, only: [:index, :show]

  resources :projects, only: [:index, :show, :edit, :update]

  resources :plugins, only: [:show]

  resources :cron_logs, only: [:index]

end
