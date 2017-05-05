require 'usable/config_multi'
require 'usable/config_register'

module Usable
  # Store and manage configuration settings. Keep methods to a minimum since this class relies on method_missing to read
  # and write to the underlying @spec object
  class Config
    include ConfigRegister
    include ConfigMulti

    # @todo Maybe keep a list of all attributes (lazy and regular)? e.g @attributes = Set.new attributes.keys.map(&:to_s)
    def initialize(attributes = {})
      @spec = OpenStruct.new(attributes)
      @lazy_loads = Set.new
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
    alias marshal_dump to_h
    alias marshal_load initialize

    def merge(other)
      to_h.merge(other)
    end

    # @param other [Hash] to update ourselves with
    def merge!(other)
      other.each do |key, val|
        @spec[key] = val
      end
      self
    end

    def method_missing(key, *args, &block)
      if block
        @lazy_loads << key
        @spec.define_singleton_method(key) { yield }
      else
        # Needs to be a symbol so we can consistently access @lazy_loads
        key = key.to_s.tr('=', '').to_sym
        if args.empty?
          if @spec[key]
            # Cleanup, just in case we loaded it another way (e.g. combining with another usable config)
            @lazy_loads.delete key
          else
            @spec[key] = call_spec_method(key)
          end
          # Define method so we don't hit method missing again
          define_singleton_method(key) { @spec[key] }
          @spec[key]
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

    def inspect
      nested, locals = @spec.to_h.partition { |_, value| value.is_a?(Usable::Config) }
      nested.map! { |key, _| [key, '{...}'] }
      locals.concat nested
      locals.map! { |key, v| %(@#{key}=#{v.inspect}) }
      vars = locals.any? ? ' ' + locals.join(', ') : ''
      "<Usable::Config:0x00#{(object_id << 1).to_s(16)}#{vars}>"
    end

    alias to_s inspect

    private

    # @note Handles the case where the value may be defined with a block, in which case it's a method
    def call_spec_method(key)
      @lazy_loads.delete key
      @spec.public_send key
    end
  end
end
