class Billing::Stripe::Subscription < ApplicationRecord
  belongs_to :team
  has_one :generic_subscription, class_name: "Billing::Subscription", as: :provider_subscription

  accepts_nested_attributes_for :generic_subscription

  def stripe_item
    {
      plan: Billing::Stripe::PriceAdapter.new(generic_subscription.price).stripe_price_id,
      quantity: generic_subscription.quantity || 1
    }
  end

  def refresh_from_checkout_session(stripe_checkout_session)
    # If the checkout is already marked as paid, we want to shortcut a few things instead of waiting for the webhook.
    if stripe_checkout_session.payment_status == "paid"
      # We need the full-blown subscription object for the end of cycle timing.
      stripe_subscription = Stripe::Subscription.retrieve(stripe_checkout_session.subscription)
      update(stripe_subscription_id: stripe_checkout_session.subscription)
      generic_subscription.update(status: :active, cycle_ends_at: Time.at(stripe_subscription.current_period_end))
      team.update(stripe_customer_id: stripe_checkout_session.customer)
    end
  end

  def update_included_prices(subscription_items)
    subscription_item = subscription_items.first

    stripe_price_id = subscription_item.dig("price", "id")

    # See if we're already including a matching price locally.
    price = Billing::Stripe::PriceAdapter.find_by_stripe_price_id(stripe_price_id)
    generic_subscription.update(
      price: price,
      quantity: subscription_item.dig("quantity")
    )
  end

  def provider_name
    "stripe"
  end
end
