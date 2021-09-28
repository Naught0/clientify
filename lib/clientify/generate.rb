# frozen_string_literal: true

module Clientify
  #
  # A collection of generator functions which help primarily with subscription imports
  # @todo add options for invoice generation, and other objects
  #
  class Generate
    class << self
      #
      # Generate components from the standard CSV format
      #
      # @param [CSV::Row] row
      #
      # @return [Array<Hash>, nil]
      #
      def components(row)
        components = row.map do |k, v|
          next if k.nil?
          next if v.nil?
          next unless k.include? 'component_id'

          id, ppid = k.scan(/\[(\d+)\]/).flatten
          data = {
            component_id: id,
            price_point_id: ppid
          }
          case k
          when /on_off/
            data[:enabled] = !%w[0 false off].include?(v&.to_s&.downcase)
          when /metered/
            data[:unit_balance] = v.to_f
          when /quantity/
            data[:allocated_quantity] = v.to_f
          end

          data.compact
        end.compact

        components.empty? ? nil : components
      end

      #
      # Generates metafields for subscription / customer creation
      #
      # @param [CSV::Row] row
      # @param [String] type 'customer' or 'subscription' to be matched against the spreadsheet
      #
      # @return [Hash] { metafield: metadata }
      #
      def metafields(row, type)
        metafields = row.map do |k, v|
          next if k.nil?
          next if v.nil?
          next unless k.include? "#{type}_metafield"

          { k.scan(/\[(.+)\]/).flatten[0] => v.to_s }
        end.compact.reduce({}, :update)

        metafields.empty? ? nil : metafields
      end

      #
      # Generates a customer object
      #
      # @param [CSV::Row] row
      # @param [Boolean] test if true, email is faked. e.g. `james@gmail.com` becomes `james@gmail.example.com`
      #
      # @see https://reference.chargify.com/v1/customers/create-customer Create customer request
      #
      # @return [Hash] API input object
      #
      def customer(row, test: true)
        fake_email = if row['customer_email'].nil?
                       nil
                     else
                       "#{row['customer_email'].gsub(/@.+/,
                                                     '')}@#{row['customer_email'][/(?<=@)[^.]*.[^.]*(?=\.)/,
                                                                                  0]}.example.com"
                     end
        cust = {
          first_name: row['customer_first_name'],
          last_name: row['customer_last_name'],
          reference: row['customer_reference'],
          email: (test ? fake_email : row['customer_email']),
          organization: row['customer_organization'],
          address: row['customer_address'],
          address_2: row['customer_address_2'],
          city: row['customer_city'],
          state: row['customer_state'],
          zip: row['customer_zip'],
          country: row['customer_country'],
          phone: row['customer_phone'],
          vat_number: row['customer_vat_number'],
          metafields: Generate.metafields(row, 'customer')
        }.compact
        # Return nil so that .compact has expected results later
        cust.empty? ? nil : cust
      end

      #
      # Generates a payment profile
      #
      # @param [CSV::Row] row
      # @param [Boolean] test replaces `current_vault` with 'bogus' and `vault_token` with `1`
      #
      # @see https://reference.chargify.com/v1/payment-profiles/create-a-payment-profile Create payment profile
      #
      # @return [Hash, nil] API input object
      #
      # @todo support bank account / ACH
      #
      def payment_profile(row, test: true)
        pp = {
          first_name: row['payment_profile_first_name'],
          last_name: row['payment_profile_last_name'],
          full_number: row['payment_profile_full_number'],
          cvv: row['payment_profile_cvv'],
          last_four: row['payment_profile_last_four'],
          card_type: row['payment_profile_card_type'],
          expiration_month: row['payment_profile_expiration_month'],
          expiration_year: row['payment_profile_expiration_year'],
          billing_address: row['payment_profile_billing_address'],
          billing_address_2: row['payment_profile_billing_address_2'],
          billing_city: row['payment_profile_billing_city'],
          billing_state: row['payment_profile_billing_state'],
          billing_country: row['payment_profile_billing_country'],
          billing_zip: row['payment_profile_billing_zip'],
          current_vault: (test ? 'bogus' : row['payment_profile_current_vault']),
          vault_token: (test ? 1 : row['payment_profile_vault_token']),
          customer_vault_token: (test ? 1 : row['payment_profile_customer_vault_token'])
        }.compact

        pp.empty? ? nil : pp
      end

      #
      # Generates a subscription. Notably does NOT handle hierarchical customer structures.
      #
      # @param [CSV::Row] row
      # @param [String] customer_id
      # @param [String] customer_reference
      # @param [Boolean] test passed to each other generator function. Uses 'bogus' gateway on payment profiles with
      #   token value 1. Uses phony email for `customer_email` field e.g. `test@chargify.com` becomes
      #   `test@chargify.example.com`
      # @see https://reference.chargify.com/v1/subscriptions/create-subscription-request
      #  Create subscription request model
      #
      # @return [Hash] api input object
      #
      def subscription(row, customer_id: nil, customer_reference: nil, test: true)
        {
          subscription: {
            payment_collection_method: row['payment_collection_method'],
            coupon_code: row['coupon_code'],
            next_billing_at: row['next_billing_at'],
            previous_billing_at: row['previous_billing_at'],
            reference: row['subscription_reference'],
            product_id: row['product_id'],
            product_price_point: row['product_price_point'],
            net_terms: row['net_terms'],
            currency: row['currency'],
            receives_invoice_emails: row['receives_invoice_emails'],
            import_mrr: true,
            customer_id: customer_id,
            customer_reference: customer_reference,
            customer_attributes: (customer_id.nil? ? Generate.customer(row, test: test) : nil),
            components: Generate.components(row),
            payment_profile_attributes: Generate.payment_profile(row, test: test),
            metafields: Generate.metafields(row, 'subscription')
          }.compact
        }
      end
    end
  end
end
