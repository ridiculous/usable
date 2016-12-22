module Usable
  module ConfigMulti
    # It's important to define all block specs we need to lazy load
    def +(other)
      config = clone
      specs = other.spec.to_h
      specs.each { |key, val| config[key] = val }
      methods = other.spec.singleton_methods - specs.keys
      methods.map! { |name| name.to_s.tr('=', '').to_sym }
      methods.uniq!
      methods.each do |name|
        config.spec.define_singleton_method(name) do
          other.spec.public_method(name).call
        end
        config.instance_variable_get(:@lazy_loads) << name
      end
      config
    end
  end
end
