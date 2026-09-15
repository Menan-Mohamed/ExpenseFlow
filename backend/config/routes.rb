Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get "me", to: "me#show"
    end

    namespace :v2 do
      resources :expenses, only: [:index, :show, :create, :update, :destroy]
      post "expenses/:id/submit", to: "expenses#submit"
      resources :categories, only: [:index]
    end
  end
end
