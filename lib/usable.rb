require "ostruct"
require "delegate"
require "usable/version"

module Usable

  autoload :ModExtender, 'usable/mod_extender'
  autoload :Config, 'usable/config'

  def usable_config
    @usable_config ||= Config.new
  end
  attr_writer :usable_config

  # @description Configures the +available_methods+ of a module using the given options or block and then includes it on
  #   the target class. Checks if there is a module named UsableSpec within the given mods namespace and uses the instance of
  #   methods of that as the +available_methods+
  #
  # @example
  #
  #   class Example
  #     extend Usable
  #     usable VersionKit, only: :save_version
  #   end
  #
  # @note Hides methods
  # @note We include the primary mod when there is a UsableSpec set because any instance method defined on the mod are not
  #   configurable and should therefore takes precedence over those defined in the UsableSpec
  # @return [Module] the anonymous module modified using @usable_config
  def usable(mod, options = {})
    options.each { |k, v| usable_config.public_send "#{k}=", v }
    yield usable_config if block_given?
    mod_ext = ModExtender.new mod, usable_config
    usable! mod_ext.call
    usable! mod if mod_ext.has_spec?
    mod_ext
  end

  # @description Directly include a module whose methods you want made available in +usable_config.available_methods+
  def usable!(mod)
    usable_config.modules << mod
    send :include, mod
  end
end
