FactoryBot.define do
  factory :billing_stripe_subscription, class: "Billing::Stripe::Subscription" do
    team { nil }
    stripe_subscription_id { "sub_yyz" }
  end
end
