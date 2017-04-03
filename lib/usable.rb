require 'set'
require 'ostruct'
require 'delegate'
require 'usable/version'
require 'usable/mod_extender'
require 'usable/config'

module Usable
  def self.logger
    @logger ||= begin
      require 'logger'
      Logger.new(STDOUT).tap do |config|
        config.formatter = proc { |*args| "[#{name}] #{args[0]}: #{args[-1]}\n" }
        config.level = Logger::ERROR
      end
    end
  end

  def self.logger=(obj)
    @logger = obj
  end

  # Keep track of extended classes and modules so we can freeze all usables on boot in production environments
  def self.extended_constants
    @extended_constants ||= Set.new
  end

  def self.freeze
    logger.debug { "freezing! #{extended_constants.to_a}" }
    extended_constants
    super
    # This may eager load classes, which is why we freeze ourselves first,
    # so the +extended+ hook doesn't try to modify @extended_constants while we're iterating over it
    extended_constants.each { |const| const.usables.freeze }
    self
  end

  def self.extended(base)
    if base.is_a? Class
      # Define an instance level version of +usables+
      base.class_eval do
        def usables
          self.class.usables
        end

        def usable_method(method_name)
          self.class.usable_method(self, method_name)
        end
      end
    end

    unless base.respond_to?(:config)
      base.instance_eval do
        def config(&block)
          if block
            usables.instance_eval &block
          else
            usables
          end
        end
      end
    end
    extended_constants << base unless Usable.frozen?
  end

  def self.copy_usables(context, recipient)
    unless Usable.frozen?
      recipient.usables += context.usables
      Usable.extended_constants << recipient
    end
  end

  def inherited(base)
    Usable.copy_usables(self, base)
    super
  end

  def extended(base)
    return if base === self
    base.extend(Usable) unless base.respond_to?(:usables)
    Usable.copy_usables(self, base)
    super
  end

  def included(base)
    base.extend(Usable) unless base.respond_to?(:usables)
    Usable.copy_usables(self, base)
    super
  end

  def usables
    @usables ||= Config.new
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
  # @return self
  def usable(*args, &block)
    options = args.last.is_a?(Hash) ? args.pop : {}
    args.each do |mod|
      ModExtender.new(mod, only: options.delete(:only), method: options.delete(:method)).call self
      # Define settings on @usables and on the scoped @usables
      scope = Config.new
      if mod.name
        scope_name = mod.name.split('::').last.gsub(/\B([A-Z])([a-z_0-9])/, '_\1\2').downcase
        usables[scope_name] = scope
      end
      if mod.respond_to? :usables
        scope += mod.usables
        self.usables += mod.usables
      end
      # any left over -options- are considered "config" settings
      if options
        [scope, usables].each { |x| options.each { |k, v| x[k] = v } }
      end
      if block_given?
        [scope, usables].each { |x| x.instance_eval &block }
      end
      if mod.const_defined?(:InstanceMethods, false)
        send :include, mod.const_get(:InstanceMethods, false)
      end
      if mod.const_defined?(:ClassMethods, false)
        send :extend, mod.const_get(:ClassMethods, false)
      end
    end
    self
  end

  # @return [Method] bound to the given -context-
  def usable_method(context, method_name)
    usables.available_methods[method_name].bind(context)
  end
end

require 'usable/railtie' if defined?(Rails::Railtie)
