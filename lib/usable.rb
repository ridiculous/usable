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


# @description TEST CASES

# module Versionable
#   def versions
#     "Saving #{self.class.config.max_versions} versions to #{self.class.config.table_name}"
#   end
# end
#
# class Model
#   extend Usable
#
#   # with options hash
#   use Versionable, table_name: 'custom_versions'
#
#   # or with block
#   use Versionable do |config|
#     config.max_versions = 10
#   end
# end
#
# Model.config.table_name #=> 'custom_versions'
# Model.new.versions #=> "Saving 10 versions to custom_versions"
#
