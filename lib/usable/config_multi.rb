module Usable
  module ConfigMulti
    # It's important to define all block specs we need to lazy load
    # Set block specs to nil values so it will fallback to calling the underlying singleton method defined by Config#method_missing
    def +(other)
      config = clone
      specs = other.spec.to_h
      specs.each { |key, val| config[key] = val }
      methods = other.spec.singleton_methods - specs.keys
      methods.each do |name|
        config.spec[name] = nil
        config.spec.define_singleton_method(name) do
          other.spec.public_method(name).call
        end
      end
      config
    end
  end
end
