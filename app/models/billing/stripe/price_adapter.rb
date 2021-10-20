class Billing::Stripe::PriceAdapter
  def initialize(price)
    @price = price
  end

  def env_key
    "STRIPE_PRODUCT_#{@price.id}_PRICE_ID".upcase
  end

  def stripe_price_id
    ENV[env_key]
  end

  def matches_stripe_price?(stripe_price)
    @price.amount == stripe_price.unit_amount &&
      @price.interval == stripe_price.recurring.interval &&
      @price.duration == stripe_price.recurring.interval_count
  end

  def self.find_by_stripe_price_id(stripe_price_id)
    Billing::Price.all.detect { |price| new(price).stripe_price_id == stripe_price_id }
  end
end
