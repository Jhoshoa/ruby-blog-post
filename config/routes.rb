Rails.application.routes.draw do
  # Authentication
  get "sign_up", to: "registrations#new", as: :sign_up
  post "sign_up", to: "registrations#create"
  get "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  resources :posts do
    resources :comments, only: [:create, :destroy]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"
end
