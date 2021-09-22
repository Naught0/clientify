module Clientify
  # frozen_string_literal: true

  class Client
    def initialize(config, log: true, log_fn: 'log/import.log')
      require 'http'
      require 'json'
      @auth = HTTP.basic_auth({ user: config[:api_key], pass: 'x' })
      @base = "https://#{config[:subdomain]}.chargify.com"

      return unless log

      require 'httplog'
      HttpLog.configure do |conf|
        conf.logger = Logger.new(log_fn)
        conf.enabled = true
        conf.log_headers = false
        conf.log_benchmark = false
        conf.log_data = true
        conf.log_response = true
      end
    end

    class << self
      #
      # Takes a HTTP::Response and returns a hash.
      # If there is an error, `:errors` will be populated
      # If there is an non JSON serializable response, it is cast to a string
      # and returned under the `:response` key
      #
      # @param [HTTP::Response] resp HTTP response
      #
      # @return [Hash]
      #
      def to_hash_sym(resp)
        return { errors: resp.body.to_s, status: resp.code } unless resp.code < 400

        JSON.parse(resp.body, symbolize_names: true)
      rescue JSON::ParserError
        { response: resp.body.to_s }
      end
    end

    #
    # Makes a POST request to the Chargify API
    #
    # @param [String] url the relative path of the endpoint e.g. `/subscriptions.json`
    # @param [Hash] payload
    #
    # @return [Hash] Chargify API resposne
    #
    def post(url, payload: nil)
      Client.to_hash_sym @auth.post("#{@base}#{url}", json: payload)
    end

    #
    # Makes a PUT request to the Chargify API
    #
    # @param [String] url the relative path of the endpoint e.g. `/subscriptions/123456789.json`
    # @param [Hash] payload
    #
    # @return [Hash] Chargify API response
    #
    def put(url, payload: nil)
      Client.to_hash_sym @auth.put("#{@base}#{url}", json: payload)
    end

    #
    # Makes a GET request to the Chargify API
    #
    # @param [String] url the relative path of the endpoint e.g. `/customers.json`
    # @param [Hash] params URL parameters for the GET request in Hash form e.g. `{ q: 'test@example.net' }`
    #
    # @return [Hash] Chargify API response
    #
    def get(url, params: nil)
      Client.to_hash_sym @auth.get("#{@base}#{url}", params: params)
    end

    #
    # Makes a DELETE request to the Chargify API
    #
    # @param [String] url the relative path of the endpoint e.g. `/customers.json`
    # @param [Hash] payload
    #
    # @return [Hash] Chargify API response
    #
    def delete(url, payload: nil)
      Client.to_hash_sym @auth.delete("#{@base}#{url}", json: payload)
    end
  end
end
