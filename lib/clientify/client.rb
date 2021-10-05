module Clientify
  # frozen_string_literal: true
  require 'httparty'
  require 'json'

  class Client
    include HTTParty

    def initialize(config, log: true, log_fn: 'log/import.log')
      @base_uri = "https://#{config[:subdomain]}.chargify.com"
      @options = {
        format: :plain,
        basic_auth: { username: config[:api_key], password: 'x' },
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
      }
      return unless log

      require 'httplog'
      HttpLog.configure do |conf|
        conf.logger = ::Logger.new(log_fn)
        conf.enabled = true
        conf.log_headers = false
        conf.log_benchmark = false
        conf.log_data = true
        conf.log_response = true
      end
    end

    #
    # Give the people what they want
    #
    # @param [HTTParty::Response] resp
    #
    # @return [Hash]
    #
    def self.to_resp(resp)
      begin
        return JSON.parse(resp.body, symbolize_names: true) if resp.code < 400
      rescue JSON::ParserError
        return { response: resp.body }
      end

      { errors: resp.body, code: resp.code } if resp.code >= 400
    end

    #
    # Make a GET request
    #
    # @param [String] url relative path
    # @param [Hash] params
    #
    # @return [Hash, Array<Hash>]
    #
    def get(url, params: nil)
      Client.to_resp self.class.get("#{@base_uri}#{url}", @options.merge({ query: params }))
    end

    #
    # Make a POST request
    #
    # @param [String] url relative path
    # @param [Hash, Array, nil] payload
    # @param [Hash, nil] params
    #
    # @return [Hash, Array<Hash>]
    #
    def post(url, payload: nil, params: nil)
      Client.to_resp self.class.post("#{@base_uri}#{url}", @options.merge({ query: params, body: payload.to_json }).compact)
    end

    #
    # Make a PUT request
    #
    # @param [String] url relative path
    # @param [Hash, Array, nil] payload
    # @param [Hash, Array<Hash>] params URL params
    #
    # @return [Hash]
    #
    def put(url, payload: nil, params: nil)
      Client.to_resp self.class.put("#{@base_uri}#{url}",
                                    @options.merge({ query: params, body: payload.to_json }).compact)
    end

    #
    # Make a DELETE request
    #
    # @param [String] url relative URL to base_uri
    # @param [Hash, Array, nil] payload
    # @param [Hash] params
    #
    # @return [Hash, Array<Hash>]
    #
    def delete(url, payload: nil, params: nil)
      Client.to_resp self.class.delete("#{@base_uri}#{url}",
                                       @options.merge({ query: params, body: payload.to_json }).compact)
    end
  end
end
