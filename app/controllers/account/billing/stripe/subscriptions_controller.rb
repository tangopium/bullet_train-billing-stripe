class Account::Billing::Stripe::SubscriptionsController < Account::ApplicationController
  account_load_and_authorize_resource :subscription, through: :team, through_association: :billing_stripe_subscriptions, member_actions: [:upgrade, :checkout, :refresh, :portal]

  # GET/POST /account/billing/stripe/subscriptions/:id/checkout
  # GET/POST /account/billing/stripe/subscriptions/:id/checkout.json
  def checkout
    trial_days = @subscription.generic_subscription.price.trial_days
    allow_promotion_codes = @subscription.generic_subscription.price.allow_promotion_codes.present?

    session_attributes = {
      payment_method_types: ["card"],
      subscription_data: {
        items: [@subscription.stripe_item],
        trial_settings: {end_behavior: {missing_payment_method: 'cancel'}},
      }.merge(trial_days ? {trial_period_days: trial_days} : {}),
      customer: @team.stripe_customer_id,
      client_reference_id: @subscription.id,
      success_url: CGI.unescape(url_for([:refresh, :account, @subscription, session_id: "{CHECKOUT_SESSION_ID}"])),
      cancel_url: url_for([:account, @subscription.generic_subscription]),
      allow_promotion_codes: allow_promotion_codes,
      automatic_tax: { enabled: true }
    }

    unless @team.stripe_customer_id
      session_attributes[:customer_email] = current_membership.email
    end

    # Stripe requires that Checkout Sessions having different attributes must
    # have different idempotency keys, so include the updated_at in the key.
    idempotency_key = "#{t("application.name").parameterize.underscore }:subscription:#{@subscription.id}:#{@subscription.updated_at.to_i}"

    session = Stripe::Checkout::Session.create(session_attributes, idempotency_key: idempotency_key)

    redirect_to session.url, allow_other_host: true
  end

  def upgrade
    @subscription.update(subscription_params)

    session_attributes = {
      id: @subscription.stripe_subscription_id,
      subscription_data: {
        items: [@subscription.stripe_item]
      }
    }

    stripe_subscription = Stripe::Subscription.retrieve(
      @subscription.stripe_subscription_id
    )

    Stripe::Subscription.update(
      @subscription.stripe_subscription_id,
      {
        items: [
          {
            id: stripe_subscription.items.data[0].id,
            price: @subscription.stripe_item[:plan]
          }
        ],
        trial_end: 'now',
        proration_behavior: 'create_prorations',
        billing_cycle_anchor: 'now'
      }
    )

    redirect_to account_billing_subscription_path(@subscription.generic_subscription)
  end

  # POST /account/billing/stripe/subscriptions/:id/portal
  # POST /account/billing/stripe/subscriptions/:id/portal.json
  def portal
    session = Stripe::BillingPortal::Session.create({
      customer: @team.stripe_customer_id,
      return_url: url_for([:account, @subscription.generic_subscription])
    })

    redirect_to session.url, allow_other_host: true
  end

  # GET /account/billing/stripe/subscriptions/:id/refresh
  # GET /account/billing/stripe/subscriptions/:id/refresh.json
  def refresh
    # If the checkout session is paid already, we want to do a couple things quickly without waiting for a webhook.
    checkout_session = Stripe::Checkout::Session.retrieve(params[:session_id])
    @subscription.refresh_from_checkout_session(checkout_session)

    redirect_to [:account, @subscription.generic_subscription.team], notice: t("billing/stripe/subscriptions.notifications.refreshed")
  end

  def subscription_params
    params.require(:billing_stripe_subscription).permit(generic_subscription_attributes: [:id, :price_id, :product_id])
  end
end
