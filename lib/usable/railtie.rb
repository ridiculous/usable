class Usable::Railtie < Rails::Railtie
  config.usable_config = Struct.new(:frozen).new(false)
  config.after_initialize do |app|
    Usable.freeze if app.config.usable_config.frozen
  end
end
