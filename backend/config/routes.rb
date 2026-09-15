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
      post "expenses/:id/reopen", to: "expenses#reopen"
      resources :categories, only: [:index]

      namespace :admin do
        resources :users, only: [:index, :create, :update] do
          member do
            post :activate
            post :deactivate
          end
        end
        resources :expenses, only: [:index, :show] do
          member do
            post :approve
            post :reject
            post :reimburse
          end
        end
        resources :categories, only: [:index, :create, :update]
        resources :teams, only: [:index, :create, :update, :destroy]
        resource :report, only: [:show], controller: :reports
      end

      namespace :manager do
        resources :expenses, only: [:index, :show, :create, :update, :destroy]
        post "expenses/:id/submit", to: "expenses#submit"
        resources :team_members, only: [:index]
        resources :reviews, only: [:index, :show] do
          member do
            post :approve
            post :reject
          end
        end
      end
    end
  end
end
