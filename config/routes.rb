Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  namespace :admin do
    resources :users do
      resources :messages, only: [ :create, :destroy ]
      patch "reset"
    end
  end

  namespace :api do
    resources :messages, only: [ :create ]

    get "/webhooks/facebook", to: "webhooks#verify_facebook"
    post "/webhooks/facebook", to: "webhooks#facebook"

    get "/webhooks/instagram", to: "webhooks#verify_instagram"
    post "/webhooks/instagram", to: "webhooks#instagram"

    post "/webhooks/discord", to: "webhooks#discord"
  end
end
