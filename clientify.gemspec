Gem::Specification.new do |s|
  s.name        = 'clientify'
  s.version     = '0.0.4'
  s.summary     = 'A bundle of utilities for interacting with the Chargify API.'
  s.description = 'A light wrapper for the Chargify API with logging capabilities. Comes bundled with some relatively generic generators for common Chargify API objects.'
  s.authors     = ['James Euteneuer']
  s.email       = ['james.euteneuer@chargify.com']
  s.files       = ['lib/clientify.rb', 'lib/clientify/client.rb', 'lib/clientify/generate.rb']
  s.homepage    = 'https://github.com/Naught0/clientify'
  s.license     = 'MIT'
  s.add_dependency 'http', '~> 5.0'
  s.add_dependency 'httplog', '~> 1.5'
end
