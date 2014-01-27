Spree Preference Initializer
============================

This gem allows for configuration of a Spree application via YAML.

About
-----

Spree uses it's preferences framework for configuration. These preferences are for the entire application, models, gateways, or anything custom to your application.

http://guides.spreecommerce.com/developer/preferences.html

The problem (for some) is that these configurations are stored in the database and are either configured via Spree::Admin, migrations, console, etc, but are not transparent enough for a traditional Dev Operations team that would like to inject the preferences during deployment. For example, the preferred practice for a Rails application is for DevOps to provide the Rails database.yml for production during Chef deploy, rather than developers comitting the code change into Github.

Rather than break out of the Spree preferences model, this Gem allows for configuration of the Spree app via YAML, by placing these configurations into Spree preferences. Developers can continue to use Spree preferences but not be concerned that the actual configuration is coming from an external source provided by DevOps.

Configuring
-----------

The gem allows you to initialize your own configuration objects, Spree's core configuration object, and gateway objects.

The example belows show the use of various environment groups extending from "default". Both an app centric configuration are initialized and a Spree configuration are initialized.

```config/config.yml
default: &default
  # Configurations specific to our application.
  spree_backend_configuration: &default_spree_backend_configuration
    config_class:               'Spree::YourConfiguration'
    foo:                        'bar'

  # Configurations to Spree Core.
  # https://github.com/spree/spree/blob/master/core/app/models/spree/app_configuration.rb  
  spree_app_configuration: &default_spree_app_configuration
    config_class:               'Spree::AppConfiguration'
    site_url:                   localhost:3000
    use_s3:                     false 
    attachment_path:            ':rails_root/public/spree/products/:id/:style/:basename.:extension'

development:
  <<: *default

test: &test
  <<: *default

```

Below is an example for configuring a Gateway object. The Gateway must already exist in order for it to be set. It can be found by either ID or name for configuration.

```config/gateways.yml

default: &default
  braintree: &default_braintree
    gateway_id:                   1
    gateway_class:                'Spree::Gateway::BraintreeGateway'
    merchant_id:                  'YOUR ID'
    merchant_account_id:          'YOUR ID'
    public_key:                   'YOUR KEY'
    private_key:                  'YOUR KEY'
    client_side_encryption_key:   'YOUR KEY'
    environment:                  'sandbox'

development:
  <<: *default

test: &test
  braintree:
    <<: *default_braintree
    merchant_id:                  'test'
    merchant_account_id:          'test'
    public_key:                   'test'
    private_key:                  'test'
    client_side_encryption_key:   'test'
    environment:                  'test'

```

Lastly, you a helper is provided to load when Spree is not quite initialize. This may happen when you are the Rails initialization level i.e. environments/*.rb. In this case, a simple key, value getting is provided for the configuration group desired.

```
Spree::PreferenceInitializer.load_config_property('spree_backend_configuration', 'foo', File.dirname(__FILE__) + "/config.yml").should == 'bar'
```


Installation
------------

Add spree_preference_initializer to your Gemfile:

```ruby
gem 'spree_preference_initializer'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_preference_initializer:install
```

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_preference_initializer/factories'
```

Copyright (c) 2014 [HoyaBoya], released under the New BSD License
