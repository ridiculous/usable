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

      def usable_method(method_name)
        self.class.usable_method(self, method_name)
      end
    end
    unless base.is_a? Class
      base.instance_eval do
        def config(&block)
          usables(&block)
        end unless defined? config
      end
    end
  end

  # @description Read and write configuration options
  def usables
    @usables ||= Config.new
    return @usables unless block_given?
    @usables.instance_eval &Proc.new
  end

  attr_writer :usables

  # @description Includes the given module with a set of options or block to configure it
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
  # @param [Module] mod
  # @param [Hash] options Customize the extension of the module as well as define config settings on the target
  # @option [Array,Symbol]  :only Limit which methods are copied from the module
  # @option [String,Symbol] :method (:include) The method to use for including the module
  # @return [ModExtender] containing the original and modified module
  def usable(mod, options = {}, &block)
    usable_options = { only: options.delete(:only), method: options.delete(:method) }
    # Define settings on @usables and on the scoped @usables
    scope = Config.new
    if mod.name
      scope_name = mod.name.split('::').last.gsub(/\B([A-Z])([a-z_0-9])/, '_\1\2').downcase
      usables[scope_name] = scope
    end
    if mod.respond_to? :usables
      mod.usables.each do |k, v|
        [scope, usables].each { |x| x.spec k, v }
      end
    end
    [scope, usables].each { |x| options.each { |k, v| x[k] = v } }
    [scope, usables].each { |x| x.instance_eval &block } if block_given?
    ModExtender.new(mod, usable_options).call self
    send :include, mod.const_get(:InstanceMethods) if const_defined? :InstanceMethods
    send :extend, mod.const_get(:ClassMethods) if const_defined? :ClassMethods
    self
  end

  # @return [Method] bound to the given -context-
  def usable_method(context, method_name)
    usables.available_methods[method_name].bind(context)
  end
end
