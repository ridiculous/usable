require "ostruct"
require "usable/version"

module Usable
  def usable_config
    @usable_config ||= Config.new
  end

  alias_method :config, :usable_config unless method_defined?(:config)

  def usable(mod, options = {})
    options.each { |k, v| usable_config.public_send "#{k}=", v }
    if block_given?
      yield usable_config
    end
    wrapped_mod = spec(mod).dup
    wrapped_mod.prepend build_null_mod(wrapped_mod)
    usable_config.modules[mod] = wrapped_mod
    if has_spec?(mod)
      send :include, mod
    else
      send :include, usable_config.modules[mod]
    end
  end

  # @description Stub out any "unwanted" methods
  def build_null_mod(mod)
    unwanted = usable_config.only ? mod.instance_methods - Array(usable_config.only) : []
    Module.new do
      unwanted.each do |method_name|
        define_method(method_name) { |*| }
      end
    end
  end

  def has_spec?(mod)
    mod.const_defined?(:Spec)
  end

  def spec(mod)
    if has_spec?(mod)
      mod.const_get(:Spec)
    else
      mod
    end
  end

  class Config < OpenStruct
    def available_methods
      modules.each_with_object({}) do |(_, mod_copy), result|
        mod_copy.instance_methods.each do |method_name|
          result[method_name] = mod_copy.instance_method method_name
        end
      end
    end

    def modules
      @modules ||= {}
    end
  end
end
