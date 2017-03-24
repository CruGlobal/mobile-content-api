# frozen_string_literal: true
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/systems', to: 'systems#systems'
  get '/systems/:id', to: 'systems#resources'

  get '/resources/:id', to: 'resources#meta'

  get '/translations/:id', to: 'translations#download_translated_resource'

  get '/drafts', to: 'drafts#page'
  post '/drafts', to: 'drafts#create_draft'
  put '/drafts/:id', to: 'drafts#publish_draft'

  post '/auth', to: 'auth#auth_token'
end
