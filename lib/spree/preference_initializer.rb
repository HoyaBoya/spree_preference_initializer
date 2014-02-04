# This class takes standard YML configurations and loads them into the appropriate Spree preference based models.
module Spree
  class PreferenceInitializer

    CONFIG_CLASS =    'config_class'
    GATEWAY_CLASS =   'gateway_class'
    GATEWAY_ID =      'gateway_id'
    GATEWAY_NAME =    'gateway_name'

    @@warnings = []

    class << self

      def warnings
        @@warnings
      end

      def reset!
        @@warnings = []
      end

      def load_config_property(context, property, file = "#{Rails.root}/config/config.yml")
        YAML.load_file(file)[Rails.env][context][property]
      end

      ##
      # Load config.yml into a Spree preference model or global Spree configurations.
      #
      def load_configs(file = "#{Rails.root}/config/config.yml")
        config = nil

        # Load configurations in config.yml to the appropriate configuration object.
        # This allows Devops to set configurations via chef, but keep using the existing Spree framework for preferences.
        # http://guides.spreecommerce.com/developer/preferences.html
        YAML.load_file(file)[Rails.env].each_pair do |key, value|
          # Get the config class that owns the configuration
          config = value[CONFIG_CLASS].constantize.new
          # Write the configuration
          value.each_pair do |app_key, app_value|
            if app_key == CONFIG_CLASS
              next
            end

            unless config.has_preference?(app_key)
              msg = "#{app_key} is not a preference on #{config}"
              Rails.logger.warn msg
              @@warnings << msg
              next
            end

            # If the property isn't what we want, then set
            if config[app_key] != app_value
              config[app_key] = app_value
            end
          end
        end

        # Insure that everything was injected or explode
        if config.respond_to?(:valid?) && config.valid? == false
          raise "#{config_class} IS NOT VALID #{config.errors.messages}"
        end
      end

      ##
      # Load gateway information
      #
      def load_gateways(file = "#{Rails.root}/config/gateways.yml")
        begin
          # Load Gateway configurations from a specific YML.
          # This allows us to configure outside of Spree Admin.
          # The logic is different to how Spree models Gateway preferences vs standard preferences like above (they are not app global).
          YAML.load_file(file)[Rails.env].each_pair do |key, value|
            gateway_id = value[GATEWAY_ID]
            gateway_name = value[GATEWAY_NAME]

            gateway = if gateway_id
              value[GATEWAY_CLASS].constantize.find_by_id(gateway_id)
            else
              value[GATEWAY_CLASS].constantize.find_by_name(gateway_name)          
            end

            value.each_pair do |app_key, app_value|
              # If we have a gateway and property is not set to what we want
              if gateway && ![GATEWAY_ID, GATEWAY_NAME, GATEWAY_CLASS].include?(app_key) && gateway.get_preference(app_key) != app_value
                gateway.set_preference(app_key, app_value)
              end
            end
          end
        # On any DB that has 0 migrations, we need to catch errors to allow the migration to proceed.
        rescue ActiveRecord::StatementInvalid => e 
          raise e if Rails.env.test?
          Honeybadger.notify(e) if defined?(Honeybadger)
          Rails.logger.warn(e.message)
          Rails.logger.warn(e.backtrace.split('\n'))
          @@warnings << e.message
        end
      end
    end
  end
end
