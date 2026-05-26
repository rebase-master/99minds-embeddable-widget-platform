Rails.application.routes.draw do
  # Real-time channel for SDK instances. Mounted explicitly in API-only mode.
  # Auth happens in ApplicationCable::Connection via signed session token (Stage 1.6).
  mount ActionCable.server => "/cable"

  # Health check used by Docker, load balancers, and the demo smoke test.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :events, only: [ :create ]
      # resources :campaigns
      # namespace :sdk do
      #   resource :theme, only: [ :show ]
      #   resources :sessions, only: [ :create ]
      # end
    end
  end
end
