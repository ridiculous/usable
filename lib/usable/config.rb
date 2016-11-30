require 'usable/config_multi'
require 'usable/config_register'

module Usable
  # Store and manage configuration settings. Keep methods to a minimum since this class relies on method_missing to read
  # and write to the underlying @spec object
  class Config
    include ConfigRegister
    include ConfigMulti

    def initialize
      @spec = OpenStruct.new
    end

    def each(&block)
      @spec.to_h.each(&block)
    end

    def spec(key, value = nil)
      if value
        @spec[key.to_s.tr('=', '')] = value
      else
        # Handle the case where the value may be defined with a block, in which case it's a method
        @spec[key] ||= call_lazy_method(key)
      end
    end

    def _spec
      @spec
    end

    def [](key)
      spec key
    end

    def []=(key, val)
      spec key, val
    end

    def to_h
      _spec.to_h
    end

    alias to_hash to_h

    def call_lazy_method(key)
      @spec.public_send(key.to_s.tr('=', ''))
    end

    def method_missing(method_name, *args, &block)
      if block
        _spec.define_singleton_method(method_name) { yield }
      else
        spec method_name, *args
      end
    rescue NoMethodError
      super
    end

    def respond_to_missing?(method_name, _private = false)
      method_name.to_s.end_with?('=') || _spec.respond_to?(method_name)
    end
  end
end
