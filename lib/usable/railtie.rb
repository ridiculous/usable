class Usable::Railtie < Rails::Railtie
  config.after_initialize do
    if Rails.env !~ /test|development/
      Usable.extended_constants.map { |const| const.usables.freeze }
    end
  end
end
