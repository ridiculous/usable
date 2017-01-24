class Usable::Railtie < Rails::Railtie
  config.usable_config = Struct.new(:frozen).new(false)

  # This was the only way to consistently hook into the end of the Rails eager load process. The +after_initialize+ hook works great, except when run
  # from a rake task, which may want to manually eager load the app with Rails.application.eager_load!, in which case the order is not guaranteed
  initializer 'usable' do |app|
    if app.config.usable_config.frozen
      require 'usable/eager_load'
      app.class.prepend Usable::EagerLoad
    end
  end
end
