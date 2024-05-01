# frozen_string_literal: true

require "sidekiq/pro/web"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  resources :systems, only: [:index, :show]
  resources :languages
  resources :resource_types, only: [:index, :show]
  get "resources/suggestions", to: "resources#suggestions"

  resources :resources do
    resources :languages, controller: :resource_languages, only: [:update, :show]
    resources :translated_attributes, path: "translated-attributes", only: [:create, :update, :destroy]
    post "translations/publish", to: "resources#publish_translation"
  end
  resources :drafts
  resources :translations, only: [:index, :show]
  resources :pages, only: [:create, :update, :show]
  resources :tips, only: [:create, :update]
  resources :custom_pages, only: [:create, :update, :destroy, :show]
  resources :custom_tips, only: [:create, :destroy]

  resources :attributes, only: [:create, :update, :destroy, :show]
  resources :translated_pages, only: [:create, :update, :destroy, :show]

  resources :views, only: [:create]
  resources :follow_ups, only: [:create]

  resources :attachments

  resources :auth, only: [:create, :show]

  resources :custom_manifests, only: [:create, :update, :destroy, :show]

  resources :tool_groups, path: "tool-groups", only: [:create, :destroy, :index, :show, :update] do
    post "tools", to: "tool_groups#create_tool"
    put "tools/:id", to: "tool_groups#update_tool"
    delete "tools/:id", to: "tool_groups#delete_tool"
  end

  # Rule Languages
  resources :tool_groups, path: "tool-groups", only: [] do
    resources :rule_languages, path: "rules-language", only: [:create, :destroy, :update]
  end

  # Rule Countries
  resources :tool_groups, path: "tool-groups", only: [] do
    resources :rule_countries, path: "rules-country", only: [:create, :destroy, :update]
  end

  # Rule Praxis
  resources :tool_groups, path: "tool-groups", only: [] do
    resources :rule_praxes, path: "rules-praxis", only: [:create, :destroy, :update]
  end

  patch "user/counters/:id", to: "user_counters#update" # Legacy route for GodTools Android v5.7.0-v6.0.0
  patch "user/me/counters/:id", to: "user_counters#update" # Legacy route for GodTools Android v6.0.1+
  get "users/:user_id/counters", to: "user_counters#index"
  patch "users/:user_id/counters/:id", to: "user_counters#update"
  get "users/:id", to: "users#show"
  delete "users/:id", to: "users#destroy"
  patch "users/:id", to: "users#update"

  scope "users/:user_id/relationships" do
    resources :favorite_tools, path: "favorite-tools", only: [:index, :create]
  end
  delete "users/:user_id/relationships/favorite-tools", to: "favorite_tools#destroy"

  scope "users/:user_id" do
    resources :training_tips, path: "training-tips", only: [:create, :update, :destroy]
  end

  get "monitors/lb"
  get "monitors/commit"

  get "attachments/:id/download", to: "attachments#download"
  get "analytics/global", to: "global_activity_analytics#show"

  put "resources/:id/onesky", to: "resources#push_to_onesky"

  get "translations/files/:path",
    to: redirect("https://#{ENV.fetch("MOBILE_CONTENT_API_BUCKET")}.s3.#{ENV.fetch("AWS_REGION")}.amazonaws.com/#{Package::TRANSLATION_FILES_PATH}%{path}", status: 302),
    format: false, # these next lines are required to have the extension be part of path
    default: {format: "html"},
    constraints: {path: /.*/}

  scope "account" do
    resources :deletion_requests, only: [:show] do
      collection do
        post :facebook
      end
    end
  end

  if Rails.env.production? || Rails.env.staging?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username == ENV.fetch("SIDEKIQ_USERNAME") && password == ENV.fetch("SIDEKIQ_PASSWORD")
    end
  end
  mount Sidekiq::Web, at: "/sidekiq"

  mount ActionCable.server => "/cable"
  mount Raddocs::App => "/docs"
end
