# frozen_string_literal: true

require "sidekiq/pro/web"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /monitors/lb that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "monitors/lb", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  resources :systems, only: %i[index show]
  resources :languages
  resources :resource_types, only: %i[index show]
  get "resources/suggestions", to: "resources#suggestions"

  resources :resources do
    resources :languages, controller: :resource_languages, only: %i[update show]
    resources :translated_attributes, path: "translated-attributes", only: %i[create update destroy]
    post "translations/publish", to: "resources#publish_translation"
    collection do
      get :featured
      resources :featured, only: %i[index create update destroy], module: :resources do
        collection do
          put :mass_update
          patch :mass_update
          put :mass_update_ranked
          patch :mass_update_ranked
        end
      end
      resources :default_order, only: %i[index create update destroy], module: :resources do
        collection do
          put :mass_update
          patch :mass_update
        end
      end
    end
  end

  resources :resource_scores, only: %i[index create update destroy] do
    collection do
      put :mass_update
      patch :mass_update
      put :mass_update_ranked
      patch :mass_update_ranked
    end
  end

  resources :drafts, only: %i[index show create destroy]
  resources :translations, only: %i[index show]
  resources :pages, only: %i[create update show]
  resources :tips, only: %i[create update]
  resources :custom_pages, only: %i[create update destroy show]
  resources :custom_tips, only: %i[create destroy]

  resources :attributes, only: %i[create update destroy show]
  resources :translated_pages, only: %i[create update destroy show]

  resources :views, only: [:create]
  resources :follow_ups, only: [:create]

  resources :attachments

  resources :auth, only: %i[create show]

  resources :custom_manifests, only: %i[create update destroy show]

  resources :tool_groups, path: "tool-groups", only: %i[create destroy index show update] do
    post "tools", to: "tool_groups#create_tool"
    put "tools/:id", to: "tool_groups#update_tool"
    delete "tools/:id", to: "tool_groups#delete_tool"
  end

  # Rule Languages
  resources :tool_groups, path: "tool-groups", only: [] do
    resources :rule_languages, path: "rules-language", only: %i[create destroy update]
  end

  # Rule Countries
  resources :tool_groups, path: "tool-groups", only: [] do
    resources :rule_countries, path: "rules-country", only: %i[create destroy update]
  end

  # Rule Praxis
  resources :tool_groups, path: "tool-groups", only: [] do
    resources :rule_praxes, path: "rules-praxis", only: %i[create destroy update]
  end

  patch "user/counters/:id", to: "user_counters#update" # Legacy route for GodTools Android v5.7.0-v6.0.0
  patch "user/me/counters/:id", to: "user_counters#update" # Legacy route for GodTools Android v6.0.1+
  get "users/:user_id/counters", to: "user_counters#index"
  patch "users/:user_id/counters/:id", to: "user_counters#update"
  get "users/:id", to: "users#show"
  delete "users/:id", to: "users#destroy"
  patch "users/:id", to: "users#update"

  scope "users/:user_id/relationships" do
    resources :favorite_tools, path: "favorite-tools", only: %i[index create]
  end
  delete "users/:user_id/relationships/favorite-tools", to: "favorite_tools#destroy"

  scope "users/:user_id" do
    resources :training_tips, path: "training-tips", only: %i[create update destroy]
  end

  get "monitors/commit"

  get "attachments/:id/download", to: "attachments#download"
  get "analytics/global", to: "global_activity_analytics#show"

  get "translations/files/:path",
    to: redirect(
      "https://#{ENV.fetch("MOBILE_CONTENT_API_BUCKET")}.s3.#{ENV.fetch("AWS_REGION")}.amazonaws.com/#{Package::TRANSLATION_FILES_PATH}%<path>s", status: 302
    ),
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

  get "content_status", to: "content_status#index"

  if Rails.env.production? || Rails.env.staging?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username == ENV.fetch("SIDEKIQ_USERNAME") && password == ENV.fetch("SIDEKIQ_PASSWORD")
    end
  end
  mount Sidekiq::Web, at: "/sidekiq"

  mount ActionCable.server => "/cable"
  mount Raddocs::App => "/docs"
end
