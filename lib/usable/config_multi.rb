module Usable
  module ConfigMulti
    # It's important to define all block specs we need to lazy load
    # Set block specs to nil values so it will fallback to calling the underlying singleton method defined by Config#method_missing
    def +(other)
      config = clone
      specs = other._spec.to_h
      specs.each { |key, val| config.spec key, val }
      methods = other._spec.singleton_methods - specs.keys
      methods.each do |name|
        config._spec[name] = nil
        config._spec.define_singleton_method(name) do
          other._spec.singleton_method(name).call
        end
      end
      config
    end
  end
end
