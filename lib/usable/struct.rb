module Usable
  def self.Struct(attributes = {})
    Class.new do
      extend Usable
      self.usables = Usable::Config.new(attributes)
      define_usable_accessors
      attributes.keys.map(&:to_sym).each do |key|
        define_method(key) { @attrs[key] }
        define_method("#{key}=") { |new_val| @attrs[key] = new_val }
      end

      attr_accessor :attrs

      def initialize(attrs = {})
        @attrs = usables.merge(attrs)
      end

      def [](key)
        @attrs[key]
      end

      def []=(key, val)
        @attrs[key] = val
      end

      def each(&block)
        @attrs.each(&block)
      end

      def to_h
        @attrs.dup
      end

      alias to_hash to_h

      def merge(other)
        to_h.merge!(other)
      end

      alias + merge
    end
  end
end
