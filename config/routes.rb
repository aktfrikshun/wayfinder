Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "portal", to: "portal#index"

  resources :parents
  resources :children do
    get :insights, on: :member
    post :regenerate_insights, on: :member
    resources :chats, controller: "child_chats", only: %i[index show create] do
      post :messages, on: :member
    end
  end
  resources :attachments, controller: "attachments"
  resources :communications do
    post :reprocess, on: :member
  end
  resources :users
  post "users/:id/impersonate", to: "users#impersonate", as: :impersonate_user
  delete "impersonation", to: "impersonations#destroy", as: :stop_impersonating

  post "webhooks/postmark/inbound", to: "webhooks/postmark_inbound#create"
  post "webhooks/postmark/events", to: "webhooks/postmark_events#create"
  get "children/:id/attachments", to: "api/children_attachments#index"
  get "children/:id/communications", to: "api/children_communications#index"
  resource :password_change, only: %i[edit update]

  scope module: :profiles, path: "profile", as: :profile do
    resource :correspondent, only: %i[edit update]
  end

  scope module: :parent_portal, path: "parent", as: :parent do
    root "dashboard#index"
    resources :invitations, only: %i[index new create]
    resources :children do
      post :regenerate_alias, on: :member
      post :regenerate_insights, on: :member
      get :insights, on: :member
      resources :chats, controller: "child_chats", only: %i[index show create] do
        post :messages, on: :member
      end
      resources :communications, controller: "child_communications", except: :index do
        post :attachments, action: :create_attachment, on: :member
        delete "attachments/:attachment_id", action: :destroy_attachment, on: :member, as: :attachment
        post :reprocess, on: :member
      end
    end
    resources :communications, only: %i[index show]
  end
end
