FactoryBot.define do
  factory :webhooks_incoming_stripe_webhook, class: "Webhooks::Incoming::StripeWebhook" do
    data { "" }
    processed_at { "2021-03-16 18:04:09" }
    verified_at { "2021-03-16 18:04:09" }
  end
end
