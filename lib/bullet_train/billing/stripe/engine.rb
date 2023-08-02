module BulletTrain
  module Billing
    module Stripe
      class Engine < ::Rails::Engine
        initializer "bullet_train-billing.integrate" do
          config.after_initialize do
            if defined?(BulletTrain::Billing.provider_subscription_attributes)
              BulletTrain::Billing.provider_subscription_attributes << :stripe_subscription_id
            end
          end
        end
      end
    end
  end
end
