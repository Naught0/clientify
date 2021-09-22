# Chargify Clientify

> Some useful utilities for interacting with the Chargify API, with particular care given to subscription imports.

## Installation

It's best practice to use `bundle` with a `Gemfile`.

Include the gem in your Gemfile  

    gem 'clientify', git: 'git@github.com:Naught0/clientify.git'

And then simply  

    $ bundle install

## Usage

e.g. Creating a subscription from a CSV  

```ruby
require 'clientify'
require 'json'
require 'csv'

def main
  # Expected config format:
  # { "api_key": "abc123", "subdomain": "test" }
  config = JSON.load_file('path/to/config.json', symbolize_names: true)
  client = Clientify::Client.new(config, log_fn: 'log/path.log')
  data = CSV.table('path/to/data.csv', header_converters: nil, converters: nil)

  # Normally you'd iterate through the entire CSV, of course
  resp = client.post('/subscriptions.json', payload: Clientify::Generate.subscription(data[0], test: true))
end

main
```  

e.g. Retrieving a payment profile by customer ID  
```ruby
require 'clientify'
require 'json'

def main
  config = { api_key: 'an api key', subdomain: 'my-subdomain' }
  client = Clientify::Client.new(config, log_fn: 'log/output.log')
  customer_id = 123456789

  payment_profile = client.get('/payment_profiles.json', params: { customer_id: customer_id })
end

main
```

