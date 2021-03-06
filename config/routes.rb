Rails.application.routes.draw do

  root 'feeds#index'

  resources :feeds, only: [:index]

  resources :projects, only: [:index, :show, :edit, :update]

  resources :plugins, only: [:show] do
    resources :versions, only: [:index, :show]
  end

  resources :cron_logs, only: [:index]

  resources :abouts, only: [:index]

end
