Rails.application.routes.draw do
  collection_actions = [:index, :new, :create] # standard:disable Lint/UselessAssignment

  namespace :webhooks do
    namespace :incoming do
      resources :stripe_webhooks
    end
  end

  namespace :account do
    shallow do
      resources :teams, only: [] do
        namespace :billing do
          resources :subscriptions, only: [] do
            namespace :stripe do
              resources :subscriptions do
                member do
                  post :checkout
                  get :checkout
                  post :portal
                  get :refresh
                end
              end
            end
          end
        end
      end
    end
  end
end
