Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/systems', to: 'systems#getSystems'
  get '/systems/:id', to: 'systems#getResources'

  get '/resources/:id', to: 'resources#getMeta'

  get '/drafts/:resourceId/:languageId/', to: 'drafts#getPage'
  post '/drafts/:resourceId/:languageId/', to: 'drafts#createDraft'

  post '/auth', to: 'auth#getAuthToken'

end
