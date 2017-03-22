# frozen_string_literal: true
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/systems', to: 'systems#systems'
  get '/systems/:id', to: 'systems#resources'

  get '/resources/:id', to: 'resources#meta'
  get '/resources/:system_id/:resource_id/:language_id/', to: 'resources#download_resource'

  get '/drafts/:resource_id/:language_id/', to: 'drafts#page'
  post '/drafts/:resource_id/:language_id/', to: 'drafts#create_draft'
  put '/drafts/:resource_id/:language_id/', to: 'drafts#publish_draft'

  post '/auth', to: 'auth#auth_token'
end
