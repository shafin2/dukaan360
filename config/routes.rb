Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  
  # User Management (for business admins) - must come before devise routes
  resources :users, constraints: { id: /\d+/ } do
    member do
      patch :assign_shop
      patch :reset_password
    end
  end
  
  devise_for :users, skip: [:registrations]
  root "home#index"
  get "home/index"
  
  # Dashboard routes
  resources :dashboard, only: [:index]
  
  # Permission Management
  resources :permissions, only: [:index, :show, :update]
  
  # Inventory Management
  resources :inventory do
    collection do
      get :low_stock
      get :stock_report
      get :valuation_report
      get :movement_history
      get :export_csv
      post :transfer_stock
      get :distribute
      post :distribute
    end
    member do
      get :edit
      patch :update
      post :restock
    end
  end
  
  # Products routes
  resources :products do
    member do
      post :add_stock
      post :assign_stock
    end
  end
  
  # Reports routes (Business Owner only)
  resources :reports, only: [:index] do
    collection do
      get :sales_by_shop
      get :receivables
      get :inventory_report
    end
  end
  
  # Sales routes
  resources :sales, only: [:index, :new, :create, :show]
  
  # Customer and billing system
  resources :customers do
    resources :bills, except: [:destroy]
    resources :payments, only: [:index, :new, :create, :show]
  end
  
  # Standalone cash bill creation - must come before bills resources
  get 'bills/new_cash_bill', to: 'bills#new_cash_bill', as: 'new_cash_bill'
  
  resources :bills do
    resources :payments, only: [:new, :create]
  end
  
  # Payments as standalone resource
  resources :payments, only: [:index, :show, :new, :create]
  
  # API endpoint for product search in sales
  get 'api/products/search', to: 'products#search'
  
  # API endpoints for searchable dropdowns
  namespace :api do
    namespace :v1 do
      get 'customers/search', to: 'customers#search'
      get 'products/search', to: 'products#search'
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by uptime monitors and load balancers.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
