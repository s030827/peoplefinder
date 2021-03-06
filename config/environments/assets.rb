# frozen_string_literal: true

Rails.application.configure do
  config.eager_load = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0.4'
end
