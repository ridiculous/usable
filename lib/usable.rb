require 'ostruct'
require 'delegate'
require 'usable/version'
require 'usable/mod_extender'
require 'usable/config'

module Usable
  def usable_config
    @usable_config ||= Config.new
  end
  attr_writer :usable_config

  # @description Configures the +available_methods+ of a module using the given options or block and then includes it on
  #   the target class. Checks if there is a module named UsableSpec within the given mods namespace and uses the instance
  #   methods of that as the +available_methods+
  #
  # @example
  #
  #   class Example
  #     extend Usable
  #     usable Mixin, only: [:foo, :bar] do |config|
  #       config.baz = "Available as `Example.usable_config.baz`"
  #     end
  #   end
  #
  # @note Hides methods
  # @note We include the primary mod when there is a UsableSpec set because any instance methods defined on the mod are
  #   not configurable and should therefore takes precedence over those defined in the UsableSpec
  #
  # @param [Module] mod
  # @param [Hash] options Customize the extension of the module as well as define config settings on the target
  # @option [Array,Symbol]  :only Limit which methods are copied from the module
  # @option [String,Symbol] :method (:include) The method to use for including the module
  # @return [ModExtender] containing the original and modified module
  def usable(mod, options = {})
    usable_options = { only: options.delete(:only), method: options.delete(:method) }
    options.each { |k, v| usable_config.public_send "#{k}=", v }
    yield usable_config if block_given?
    mod_ext = ModExtender.new mod, usable_options
    mod_ext.use! self
    mod_ext.use_original! self
    mod_ext
  end

  # @return [Method] bound to the given -context-
  def usable_method(context, method_name)
    usable_config.available_methods[method_name].bind(context)
  end
end
