FactoryBot.define do
  factory :billing_stripe_subscription, class: "Billing::Stripe::Subscription" do
    team { nil }
    stripe_customer_id { "MyString" }
    stripe_subscription_id { "MyString" }
  end
end
