Rails.application.routes.draw do
  root "home#index"

  get "/go/:id", to: "tokens#show", as: :token

  resources :reviews
  resources :feedback_requests, only: [:update]
  resources :replies, only: [:index]
  resources :invitations, only: [:update]
  resources :submissions, only: [:edit, :update]
  resources :reminders, only: [:create]

  resources :users, only: [:index, :show] do
    resources :reviews
  end

  namespace :results do
    resources :reviews, only: [:index]
    resources :users, only: [:index] do
      resources :reviews, only: [:index]
    end
  end

  get 'leadership_model', to: 'pages#leadership_model', as: :leadership_model
end
