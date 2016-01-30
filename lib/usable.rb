require "ostruct"
require "usable/version"

module Usable
  def config
    @config ||= Config.new
  end

  def use(mod, options = {})
    send :include, mod unless self < mod
    if block_given?
      yield config
    else
      options.each { |k, v| config.public_send "#{k}=", v }
    end
  end

  class Config < OpenStruct
  end
end
