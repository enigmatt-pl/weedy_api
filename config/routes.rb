# == Route Map
#
#                                   Prefix Verb   URI Pattern                                                                                       Controller#Action
#                         new_user_session GET    /users/sign_in(.:format)                                                                          devise/sessions#new
#                             user_session POST   /users/sign_in(.:format)                                                                          devise/sessions#create
#                     destroy_user_session DELETE /users/sign_out(.:format)                                                                         devise/sessions#destroy
#                        new_user_password GET    /users/password/new(.:format)                                                                     devise/passwords#new
#                       edit_user_password GET    /users/password/edit(.:format)                                                                    devise/passwords#edit
#                            user_password PATCH  /users/password(.:format)                                                                         devise/passwords#update
#                                          PUT    /users/password(.:format)                                                                         devise/passwords#update
#                                          POST   /users/password(.:format)                                                                         devise/passwords#create
#                 cancel_user_registration GET    /users/cancel(.:format)                                                                           devise/registrations#cancel
#                    new_user_registration GET    /users/sign_up(.:format)                                                                          devise/registrations#new
#                   edit_user_registration GET    /users/edit(.:format)                                                                             devise/registrations#edit
#                        user_registration PATCH  /users(.:format)                                                                                  devise/registrations#update
#                                          PUT    /users(.:format)                                                                                  devise/registrations#update
#                                          DELETE /users(.:format)                                                                                  devise/registrations#destroy
#                                          POST   /users(.:format)                                                                                  devise/registrations#create
#                       rails_health_check GET    /up(.:format)                                                                                     rails/health#show
#                                     root GET    /                                                                                                 status#index
#                     custom_storage_proxy GET    /uploads/:signed_id/*filename(.:format)                                                           active_storage/blobs/proxy#show
#                  new_api_v1_user_session GET    /api/v1/users/sign_in(.:format)                                                                   api/v1/users/sessions#new
#                      api_v1_user_session POST   /api/v1/users/sign_in(.:format)                                                                   api/v1/users/sessions#create
#              destroy_api_v1_user_session DELETE /api/v1/users/sign_out(.:format)                                                                  api/v1/users/sessions#destroy
#                 new_api_v1_user_password GET    /api/v1/users/password/new(.:format)                                                              api/v1/passwords#new
#                edit_api_v1_user_password GET    /api/v1/users/password/edit(.:format)                                                             api/v1/passwords#edit
#                     api_v1_user_password PATCH  /api/v1/users/password(.:format)                                                                  api/v1/passwords#update
#                                          PUT    /api/v1/users/password(.:format)                                                                  api/v1/passwords#update
#                                          POST   /api/v1/users/password(.:format)                                                                  api/v1/passwords#create
#          cancel_api_v1_user_registration GET    /api/v1/users/cancel(.:format)                                                                    api/v1/users/registrations#cancel
#             new_api_v1_user_registration GET    /api/v1/users/sign_up(.:format)                                                                   api/v1/users/registrations#new
#            edit_api_v1_user_registration GET    /api/v1/users/edit(.:format)                                                                      api/v1/users/registrations#edit
#                 api_v1_user_registration PATCH  /api/v1/users(.:format)                                                                           api/v1/users/registrations#update
#                                          PUT    /api/v1/users(.:format)                                                                           api/v1/users/registrations#update
#                                          DELETE /api/v1/users(.:format)                                                                           api/v1/users/registrations#destroy
#                                          POST   /api/v1/users(.:format)                                                                           api/v1/users/registrations#create
#                      api_v1_users_avatar PUT    /api/v1/users/avatar(.:format)                                                                    api/v1/users/registrations#avatar
#                approve_api_v1_admin_user POST   /api/v1/admin/users/:id/approve(.:format)                                                         api/v1/admin/users#approve
#              unapprove_api_v1_admin_user POST   /api/v1/admin/users/:id/unapprove(.:format)                                                       api/v1/admin/users#unapprove
#                credits_api_v1_admin_user PATCH  /api/v1/admin/users/:id/credits(.:format)                                                         api/v1/admin/users#update_credits
#            full_delete_api_v1_admin_user DELETE /api/v1/admin/users/:id/full_delete(.:format)                                                     api/v1/admin/users#full_delete
#                       api_v1_admin_users GET    /api/v1/admin/users(.:format)                                                                     api/v1/admin/users#index
#                        api_v1_admin_user DELETE /api/v1/admin/users/:id(.:format)                                                                 api/v1/admin/users#destroy
#                publish_api_v1_dispensary POST   /api/v1/dispensaries/:id/publish(.:format)                                                        api/v1/dispensaries#publish
#                        api_v1_dispensary POST   /api/v1/dispensaries/:id(.:format)                                                                api/v1/dispensaries#update
#                      api_v1_dispensaries GET    /api/v1/dispensaries(.:format)                                                                    api/v1/dispensaries#index
#                                          POST   /api/v1/dispensaries(.:format)                                                                    api/v1/dispensaries#create
#                                          GET    /api/v1/dispensaries/:id(.:format)                                                                api/v1/dispensaries#show
#                                          PATCH  /api/v1/dispensaries/:id(.:format)                                                                api/v1/dispensaries#update
#                                          PUT    /api/v1/dispensaries/:id(.:format)                                                                api/v1/dispensaries#update
#                                          DELETE /api/v1/dispensaries/:id(.:format)                                                                api/v1/dispensaries#destroy
#                       api_v1_health_ping POST   /api/v1/health/ping(.:format)                                                                     api/v1/analytics#create
#                      api_v1_health_pulse POST   /api/v1/health/pulse(.:format)                                                                    api/v1/analytics/engagements#create
#        api_v1_admin_analytics_page_views GET    /api/v1/admin/analytics/page_views(.:format)                                                      api/v1/admin/analytics#page_views
#           api_v1_admin_analytics_summary GET    /api/v1/admin/analytics/summary(.:format)                                                         api/v1/admin/analytics#summary
#            rails_postmark_inbound_emails POST   /rails/action_mailbox/postmark/inbound_emails(.:format)                                           action_mailbox/ingresses/postmark/inbound_emails#create
#               rails_relay_inbound_emails POST   /rails/action_mailbox/relay/inbound_emails(.:format)                                              action_mailbox/ingresses/relay/inbound_emails#create
#            rails_sendgrid_inbound_emails POST   /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                           action_mailbox/ingresses/sendgrid/inbound_emails#create
#      rails_mandrill_inbound_health_check GET    /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#health_check
#            rails_mandrill_inbound_emails POST   /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#create
#             rails_mailgun_inbound_emails POST   /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                       action_mailbox/ingresses/mailgun/inbound_emails#create
#           rails_conductor_inbound_emails GET    /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#index
#                                          POST   /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#create
#        new_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                      rails/conductor/action_mailbox/inbound_emails#new
#            rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                      rails/conductor/action_mailbox/inbound_emails#show
# new_rails_conductor_inbound_email_source GET    /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                              rails/conductor/action_mailbox/inbound_emails/sources#new
#    rails_conductor_inbound_email_sources POST   /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                  rails/conductor/action_mailbox/inbound_emails/sources#create
#    rails_conductor_inbound_email_reroute POST   /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                               rails/conductor/action_mailbox/reroutes#create
# rails_conductor_inbound_email_incinerate POST   /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                            rails/conductor/action_mailbox/incinerates#create
#                       rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#                 rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                          GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#                rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#          rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                          GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                       rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#                update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#                     rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create

Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  root to: "status#index"

  # Custom masked routes for Active Storage
  get '/uploads/:signed_id/*filename', to: 'active_storage/blobs/proxy#show', as: :custom_storage_proxy

  namespace :api do
    namespace :v1 do
      devise_for :users, controllers: {
        sessions: 'api/v1/users/sessions',
        registrations: 'api/v1/users/registrations'
      }

      devise_scope :user do
        put 'users/avatar', to: 'users/registrations#avatar'
      end

      namespace :admin do
        resources :users, only: [:index, :destroy] do
          member do
            post :approve
            post :unapprove
            patch :credits, action: :update_credits
            delete :full_delete
          end
        end
      end

      resources :dispensaries, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :publish
          post :update # Fallback for multipart updates using POST
        end
      end

      namespace :health do
        post 'ping', to: '/api/v1/analytics#create'
        post 'pulse', to: '/api/v1/analytics/engagements#create'
      end

      namespace :admin do
        get 'analytics/page_views', to: 'analytics#page_views'
        get 'analytics/summary', to: 'analytics#summary'
      end
    end
  end
end
