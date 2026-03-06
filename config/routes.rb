Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#index"
  get "portal", to: "portal#index"

  resources :parents
  resources :children
  resources :communications
  resources :users
  post "users/:id/impersonate", to: "users#impersonate", as: :impersonate_user
  delete "impersonation", to: "impersonations#destroy", as: :stop_impersonating

  post "webhooks/postmark/inbound", to: "webhooks/postmark_inbound#create"
  get "children/:id/artifacts", to: "api/children_artifacts#index"
  get "children/:id/communications", to: "api/children_communications#index"

  scope module: :parent_portal, path: "parent", as: :parent do
    root "dashboard#index"
    resources :children
    resources :communications, only: %i[index show]
  end
end
