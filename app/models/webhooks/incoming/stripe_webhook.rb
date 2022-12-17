class Webhooks::Incoming::StripeWebhook < ApplicationRecord
  include Webhooks::Incoming::Webhook

  def process
    case type
    when "checkout.session.completed"
      # We may not know the stripe_subscription_id of the Subscription in question, so set it now.
      # While it is often set by the user navigating to subscriptions#refresh following a completed
      # Stripe Checkout Session, sometimes the user fails to navigate there.
      subscription = Billing::Stripe::Subscription.find_by(id: data.dig("data", "object", "client_reference_id"))
      subscription.update(stripe_subscription_id: data.dig("data", "object", "subscription"))
    when "customer.subscription.created", "customer.subscription.updated"
      # If the subscription is scheduled to cancel remotely, then mark it as canceling locally.
      if object.dig("cancel_at_period_end")
        topic.generic_subscription.update(status: "canceling")

      # Otherwise, map the status in Stripe to a status we can use locally.
      else
        status = case subscription_status
        when "incomplete"
          "pending"
        when "incomplete_expired"
          "canceled"
        when "trialing"
          "trialing"
        when "active"
          "active"
        when "past_due"
          "overdue"
        when "unpaid"
          "overdue"
        when "canceled"
          "canceled"
        end

        topic.generic_subscription.update(status: status)
      end

      # Inspect the subscriptions items on this subscription and ensure they're in-sync with our local entries.
      topic.update_included_prices(object.dig("items", "data"))
    end
  end

  def object
    data.dig("data", "object")
  end

  def subscription_status
    object.dig("status")
  end

  def type
    data.dig("type")
  end

  def topic
    case topic_id&.split("_")&.first
    when "sub"
      Billing::Stripe::Subscription.find_by(stripe_subscription_id: topic_id)
    end
  end

  def topic_id
    data.dig("data", "object", "id")
  end
end
