Oneclick::Application.routes.draw do

  match '/configuration' => 'configuration#configuration'

  scope "(:locale)", locale: /en|es/ do

    if Oneclick::Application.config.ui_mode == 'kiosk'
      root to: redirect('/kiosk')
    else
      root :to => "home#index"
    end

    authenticated :user do
      root :to => 'home#index'
    end

    devise_for :users, controllers: {registrations: "registrations", sessions: "sessions"}


    # everything comes under a user id
    resources :users do
      member do
        get   'profile'
        post  'update'
      end

      resources :characteristics, :only => [:new, :create, :edit, :update] do
        collection do
          get 'header'
        end
        member do
          put 'set'
        end
      end

      resources :programs, :only => [:new, :create, :edit, :update] do
        member do
          put 'set'
        end
      end

      resources :accommodations, :only => [:new, :create, :edit, :update] do
        member do
          put 'set'
        end
      end

      # user relationships
      resources :user_relationships, :only => [:new, :create] do
        member do
          get   'traveler_retract'
          get   'traveler_revoke'
          get   'traveler_hide'
          get   'delegate_accept'
          get   'delegate_decline'
          get   'delegate_revoke'
        end
      end

      # users have places
      resources :places, :only => [:index, :new, :create, :destroy, :edit, :update] do
        collection do
          get   'search'
          post  'geocode'
        end
      end

      # users have trips
      resources :trips, :only => [:show, :index, :new, :create, :destroy, :edit, :update] do
        collection do
          post  'set_traveler'
          get   'unset_traveler'
          get   'search'
          post  'geocode'
        end
        member do
          get   'repeat'
          get   'select'
          get   'details'
          get   'itinerary'
          post  'email'
          post  'email_provider'
          post  'email_itinerary'
          get   'email_itinerary2_values'
          post  'email2'
          get   'hide'
          get   'unhide_all'
          get   'skip'
          post  'rate'
          post  'comments'
          post  'admin_comments'
          get   'edit_rating'
          get   'email_feedback'
          get   'show_printer_friendly'
        end
      end

      resources :trip_parts do
        member do
          get 'unhide_all'
        end
      end

    end

    #Ratings do not come under a user id
    resources :ratings do
      member do
        get   'edit'
        post  'rate'
        post  'comments'
      end
    end

    # scope('/kiosk') do
    #   devise_for :users, as: 'kiosk', controllers: {sessions: "kiosk/sessions"}
    # end

    # match '/kiosk_user/kiosk/users/sign_in', to: 'kiosk/sessions#create'

    namespace :kiosk do
      match '/', to: 'home#index'

      # TODO can probably remove a lot of these routes
      resources :users do
        member do
          get   'profile'
          post  'update'
        end

        resources :characteristics, :only => [:new, :create, :edit, :update] do
          collection do
            get 'header'
          end
          member do
            put 'set'
          end
        end

        resources :programs, :only => [:new, :create, :edit, :update] do
          member do
            put 'set'
          end
        end

        resources :accommodations, :only => [:new, :create, :edit, :update] do
          member do
            put 'set'
          end
        end

        # user relationships
        resources :user_relationships, :only => [:new, :create] do
          member do
            get   'traveler_retract'
            get   'traveler_revoke'
            get   'traveler_hide'
            get   'delegate_accept'
            get   'delegate_decline'
            get   'delegate_revoke'
          end
        end

        # users have places
        resources :places, :only => [:index, :new, :create, :destroy, :edit, :update] do
          collection do
            get   'search'
            post  'geocode'
          end
        end

        # users have trips
        resources :trips, :only => [:show, :index, :new, :create, :destroy, :edit, :update] do
          collection do
            post  'set_traveler'
            get   'unset_traveler'
            get   'search'
            post  'geocode'
          end
          member do
            get   'repeat'
            get   'select'
            get   'details'
            get   'itinerary'
            post  'email'
            post  'email_provider'
            post  'email_itinerary'
            get   'email_itinerary2_values'
            post  'email2'
            get   'hide'
            get   'unhide_all'
            get   'skip'
            post  'rate'
            post  'comments'
            post  'admin_comments'
            get   'edit_rating'
            get   'email_feedback'
            get   'show_printer_friendly'
          end
        end

        resources :trip_parts do
          member do
            get 'unhide_all'
          end
        end

      end # kiosk

    end # user

    devise_scope :user do
      post '/kiosk/sign_in' => 'kiosk/sessions#create', as: :kiosk_user_session
      get '/kiosk/sign_in' => 'kiosk/sessions#new', as: :new_kiosk_user_session
      match '/kiosk/session/destroy' => 'kiosk/sessions#destroy', as: :destroy_kiosk_user_session
    end


    namespace :admin do
      resources :reports, :only => [:index, :show]
      resources :trips, :only => [:index]
      match '/geocode' => 'util#geocode'
      match '/' => 'home#index'
    end

    resources :services do
      member do
        get 'view'
      end
    end

    resources :esp_reader do
      collection do
        get 'upload'
        get 'confirm'
        post 'update'
      end
    end

    match '/' => 'home#index'

    match '/404' => 'errors#error_404', as: 'error_404'
    match '/422' => 'errors#error_422', as: 'error_422'
    match '/500' => 'errors#error_500', as: 'error_500'
    match '/501' => 'errors#error_501', as: 'error_501'

  end

  ComfortableMexicanSofa::Routing.admin(:path => '/cms-admin')

  mount_sextant if Rails.env.development?
  match '*not_found' => 'errors#handle404'

  # Make sure this routeset is defined last
  ComfortableMexicanSofa::Routing.content(:path => '/', :sitemap => false)

end
