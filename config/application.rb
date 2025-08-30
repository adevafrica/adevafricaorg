require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Adevafrica
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Active Job configuration
    config.active_job.queue_adapter = :sidekiq

    # CORS configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end

    # Rate limiting configuration
    config.middleware.use Rack::Attack

    # Time zone
    config.time_zone = 'Africa/Nairobi'

    # Generators configuration
    config.generators do |g|
      g.test_framework :rspec
      g.factory_bot true
      g.view_specs false
      g.helper_specs false
      g.routing_specs false
      g.controller_specs false
    end

    # Asset configuration for production
    config.assets.compile = true
    config.assets.digest = true
    config.serve_static_assets = true
  end
end


