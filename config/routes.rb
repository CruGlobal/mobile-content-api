Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/systems', to: 'systems#getSystems'
  get '/systems/:id', to: 'systems#getResources'

  get '/resources/:id', to: 'resources#getMeta'
  get '/resources/:systemId/:resourceId/:languageId/', to: 'resources#downloadResource'

  get '/drafts/:resourceId/:languageId/', to: 'drafts#getPage'
  post '/drafts/:resourceId/:languageId/', to: 'drafts#createDraft'
  put '/drafts/:resourceId/:languageId/', to: 'drafts#publishDraft'

  post '/auth', to: 'auth#getAuthToken'

end
