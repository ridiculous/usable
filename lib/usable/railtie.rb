class Usable::Railtie < Rails::Railtie
  config.usable_config = Struct.new(:frozen).new(false)

  # This was the only way to consistently hook into the end of the Rails eager load process. The +after_initialize+ hook works great, except when
  # +Rails.application.eager_load!+ is called directly from third-party gem (e.g. Resque), in which case the order is not guaranteed.
  # The solution instead is overload +eager_load!+
  initializer 'usable' do |app|
    if app.config.usable_config.frozen
      require 'usable/eager_load'
      app.class.prepend Usable::EagerLoad
    end
  end
end
