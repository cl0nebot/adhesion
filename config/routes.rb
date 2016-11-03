class CustomDomain
  def matches?(request)
    return false if request.subdomain.length <= 0 || request.subdomain == 'www'
    true
  end
end

Rails.application.routes.draw do

  root to: "home#index"

  get 'iframe_cookies_fix_redirect' => 'lti_launches#iframe_cookies_fix_redirect'
  get 'relaunch_lti_tool' => 'lti_launches#relaunch_lti_tool'

  resources :lti_launches do
    collection do
      post :index
      get :index
    end
  end

  match 'scorm_course/postback' => 'scorm_course#postback', :via => :post
  resources :scorm_course

  devise_for :users, controllers: {
    sessions: "sessions",
    registrations: "registrations",
    omniauth_callbacks: "omniauth_callbacks"
  }

  as :user do
    get     '/auth/failure'         => 'sessions#new'
    get     'users/auth/:provider'  => 'users/omniauth_callbacks#passthru'
    get     'sign_in'               => 'sessions#new'
    post    'sign_in'               => 'sessions#create'
    get     'sign_up'               => 'devise/registrations#new'
    delete  'sign_out'              => 'sessions#destroy'
  end

  resources :users

  namespace :admin do
    root :to => "lti_installs#index"
    resources :canvas_authentications
    resources :lti_installs
  end

  namespace :api do
    resources :jwts
    resources :courses do
      get 'launch' => 'courses#launch'
      get 'preview' => 'courses#preview'
      post 'import' => 'courses#import'
      resources :students, only: [:index]
      resources :sections, only: [] do
        resources :students, only: [:index]
      end
    end
  end

  mount MailPreview => 'mail_view' if Rails.env.development?

  get 'api/canvas' => 'api/canvas_proxy#proxy'
  post 'api/canvas' => 'api/canvas_proxy#proxy'
  put 'api/canvas' => 'api/canvas_proxy#proxy'
  delete 'api/canvas' => 'api/canvas_proxy#proxy'

end
