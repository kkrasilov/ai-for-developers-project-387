Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Guest-facing endpoints
  resources :event_types, only: [:index, :show] do
    resources :slots, only: [:index], module: :event_types
  end
  resources :bookings, only: [:create]

  # Owner endpoints
  namespace :owner do
    resources :bookings, only: [:index]
    resources :event_types, only: [:index, :create]
  end

  # Serve the built frontend SPA (see public/) for any other GET request,
  # so a single container can serve both the API and the UI on one port.
  get "*path", to: "spa#index", constraints: ->(req) { req.format.html? }, format: false
  root to: "spa#index"
end
