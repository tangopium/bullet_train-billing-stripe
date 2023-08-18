begin
  require "factory_bot_rails"
rescue LoadError
end

module BulletTrain
  module Billing
    module Stripe
      class Engine < ::Rails::Engine
        if defined? FactoryBotRails
          config.factory_bot.definition_file_paths += [File.expand_path("../../../../factories", __FILE__)]
        end

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
