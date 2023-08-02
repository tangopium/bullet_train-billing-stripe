require "bullet_train/billing/stripe/version"
require "bullet_train/billing/stripe/engine"

module BulletTrain
  module Billing
    module Stripe
      # Your code goes here...
    end
  end
end

def stripe_billing_enabled?
  ENV["STRIPE_SECRET_KEY"].present?
end
