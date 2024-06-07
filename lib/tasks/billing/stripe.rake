namespace :billing do
  namespace :stripe do
    desc "Populate the Stripe account with the required products."
    task populate_products_in_stripe: :environment do
      unless stripe_billing_enabled?
        # TODO Improve this error message and point them to some "getting started" documentation.
        puts "Stripe isn't enabled.".red
        next
      end

      results = {}

      # for each product or service level ..
      # e.g. [:basic, :pro].each ...
      Billing::Product.all.each do |product|
        # ensure a stripe product with the appropriate key exists.
        stripe_product_id = "#{I18n.t("application.key")}_#{product.id}"

        unless product.prices.any?
          puts "Skipping `#{stripe_product_id}` because it has no prices associated with it.".yellow
          next
        end

        begin
          name = [I18n.t("application.name"), I18n.t("billing/products.#{product.id}.name")].join(" ")
          # first check whether the product already exists.
          stripe_product = Stripe::Product.retrieve(id: stripe_product_id)
          puts "Verified `#{stripe_product.id}` exists as a product on Stripe.".yellow

          Stripe::Product.update(stripe_product_id, name: name)

          puts "Updated name of `#{stripe_product.id}` to \"#{name}\".".green
        rescue Stripe::InvalidRequestError => _
          # if it doesn't already exist, create it.
          stripe_product = Stripe::Product.create(id: stripe_product_id, name: name)
          puts "Created `#{product.id}`.".green
        end

        # e.g. [:month, :year].each do ...
        product.prices.each do |price|
          # check whether an appropriate price for this product already exists on stripe.
          stripe_prices = Stripe::Price.list(product: stripe_product.id).data

          price_adapter = Billing::Stripe::PriceAdapter.new(price)

          if (stripe_price = stripe_prices.detect { |stripe_price| price_adapter.matches_stripe_price?(stripe_price) })
            puts "Verified a price similar to the `#{price.id}` price exists for `#{stripe_product.id}`.".yellow
          else
            # if this product doesn't already haves a price at the appropriate interval, create it.
            stripe_price = Stripe::Price.create({
              product: stripe_product.id,
              unit_amount: price.amount,
              currency: price.currency,
              recurring: {interval: price.interval}
            })
            puts "Created `#{price.id}` as a `#{price.interval}` price for `#{stripe_product.id}`.".green
          end

          results[price_adapter.env_key] = stripe_price.id
        end
      end

      puts "\nOK, put the following in `config/application.yml` or wherever you configure your environment values:\n".green

      results.each do |key, value|
        puts "#{key}: #{value}".green
      end

      puts "\n"
      puts "In addition to enabling local development, those `price_*` values also let Bullet Train's test suite know what plans are available on Stripe for testing it's subscription workflows.".green
      puts "\n"
    end
  end
end
