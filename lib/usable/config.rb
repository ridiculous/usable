require 'usable/config_multi'
require 'usable/config_register'

module Usable
  # Store and manage configuration settings. Keep methods to a minimum since this class relies on method_missing to read
  # and write to the underlying @spec object
  class Config
    include ConfigRegister
    include ConfigMulti

    def initialize(attributes = {})
      @spec = OpenStruct.new(attributes)
      @lazy_loads = Set.new
      # @attributes = Set.new attributes.keys.map(&:to_s)
    end

    def spec
      @spec
    end

    def [](key)
      @spec[key]
    end

    def []=(key, val)
      @spec[key] = val
    end

    def each(&block)
      @spec.to_h.each(&block)
    end

    def to_h
      @lazy_loads.each { |key| @spec[key] = call_spec_method(key) }
      @spec.to_h
    end

    alias to_hash to_h

    def merge(other)
      to_h.merge(other)
    end

    def method_missing(key, *args, &block)
      if block
        @lazy_loads << key
        # @attributes << key.to_s
        @spec.define_singleton_method(key) { yield }
      else
        key = key.to_s.tr('=', '')
        # @attributes << key
        if args.empty?
          value = @spec[key] ||= call_spec_method(key)
          define_singleton_method(key) { @spec[key] }
          value
        else
          @spec[key] = args.first
        end
      end
    rescue NoMethodError
      super
    end

    def respond_to_missing?(method_name, _private = false)
      method_name.to_s.end_with?('=') || @spec.respond_to?(method_name)
    end

    def freeze
      to_h.each { |key, value| define_singleton_method(key) { value } }
      @spec.freeze
      super
    end

    private

    # @note Handles the case where the value may be defined with a block, in which case it's a method
    def call_spec_method(key)
      @lazy_loads.delete key
      @spec.public_send key
    end
  end
end
