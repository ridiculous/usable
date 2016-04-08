require 'ostruct'
require 'delegate'
require 'usable/version'
require 'usable/mod_extender'
require 'usable/config'

module Usable

  # @description Define an instance level version of +usables+
  def self.extended(base)
    base.class_eval do
      def usables
        self.class.usables
      end
    end
  end

  def usables
    @usables ||= Config.new
  end

  attr_writer :usables

  # @description Configures the +available_methods+ of a module using the given options or block and then includes it on
  #   the target class. Checks if there is a module named UsableSpec within the given mods namespace and uses the instance
  #   methods of that as the +available_methods+
  #
  # @example
  #
  #   class Example
  #     extend Usable
  #     usable Mixin, only: [:foo, :bar] do
  #       baz "Available as `Example.usables.baz` or `Example.usables.mixin.baz`"
  #     end
  #   end
  #
  # @note Hides methods
  # @note We include the primary mod when there is a UsableSpec set because any instance methods defined on the mod are
  #   not configurable and should therefore takes precedence over those defined in the UsableSpec
  #
  # @param [Module] mod
  # @param [Hash] options Customize the extension of the module
  # @option [Array,Symbol]  :only Limit which methods are copied from the module
  # @option [String,Symbol] :method (:include) The method to use for including the module
  # @return [ModExtender] containing the original and modified module
  def usable(mod, options = {}, &block)
    # Define settings on @usables and on the scoped @usables
    if mod.name
      scope_name = mod.name.split('::').last.gsub(/\B([A-Z])([a-z_0-9])/, '_\1\2').downcase
      usables.instance_eval "def #{scope_name}; @#{scope_name} ||= Config.new end"
      scope = usables.public_send(scope_name)
    else
      scope = Config.new
    end
    if mod.respond_to? :usables
      mod.usables.each do |k, v|
        [scope, usables].each { |x| x.spec k, v }
      end
    end
    [scope, usables].each { |x| x.instance_eval &block } if block_given?
    # Include module
    mod_ext = ModExtender.new mod, options
    mod_ext.use! self
    mod_ext.use_original! self
    mod_ext.use_class_methods! self
    mod_ext
  end

  # @return [Method] bound to the given -context-
  def usable_method(context, method_name)
    usables.available_methods[method_name].bind(context)
  end
end
