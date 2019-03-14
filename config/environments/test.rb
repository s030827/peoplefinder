Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :test
  config.active_support.deprecation = :stderr
  config.active_job.queue_adapter = :test
  config.action_mailer.default_url_options = {
    host: 'www.example.com',
    protocol: 'http'
  }
  config.action_mailer.asset_host = 'http://www.example.com'
  config.active_job.queue_adapter = :test

  # enable these features just for tests
  config.disable_open_profiles = false
end
