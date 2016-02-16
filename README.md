# Usable [![Gem Version](https://badge.fury.io/rb/usable.svg)](http://badge.fury.io/rb/usable)

A simple way to mount and configure your modules. Usable gives you control over which methods are included, and the class
level config provides a safe interface for calling them.

```ruby
module VersionKit
  def save_version
    "Saving up to #{self.class.usable_config.max_versions} versions to #{self.class.usable_config.table_name}"
  end

  def destroy_version
    "Deleting versions from #{self.class.usable_config.table_name}"
  end
end
  
class Model
  extend Usable

  usable VersionKit, only: :save_version do |config|
    config.max_versions = 10
    config.table_name = 'custom_versions'
  end
end

>> Model.usable_config.table_name
=> "custom_versions"
>> Model.new.save_version
=> "Saving up to 10 versions to custom_versions"
>> Model.usable_config.available_methods[:save_version].bind(Model.new).call
=> "Saving up to 10 versions to custom_versions"
>> Model.new.respond_to? :destroy_version     
=> false
>> Model.usable_config.available_methods[:destroy_version].bind(Model.new).call
=> nil
```
What's going on here? Well `#save_versions` is now extended onto the `Model` class, but `#destroy_version` is not!

## Confidently calling methods

We should all be writing [confident code](http://www.confidentruby.com/). That's why it is encouraged
to reference methods through the `usable_config.available_methods` hash. This way you can confidently call methods! 
Methods that are specified in the `:only` option, will return `nil` when called.

## Separate included module from configurable methods

Sometimes you want to define methods on the module but not have them be configurable. Define a module within the usable 
module namespace and name it `UsableSpec`, and `Usable` will use that module to configure the available methods. Any naming
conflicts will be resolved by giving precedence to the parent module.

For example:

```ruby
# ruby -v 2.3.0

module VersionKit
  module UsableSpec
    def version
      "yo"
    end
    
    def name
      "nope"
    end
  end
  
  def name
    "yup"
  end
  
  def self.included(base)
    puts base.usable_config.available_methods[:version].bind(self).call
  end
end

Example = Class.new.extend Usable
Example.usable VersionKit
Example.new.version               # => "yo"
Example.new.name                  # => "yup"
Example.ancestors                 # => [Example, VersionKit, Example::VersionKitUsableSpecUsed, Object, Kernel, BasicObject]
```

Noticed that Usable assigns the modified module to a constant with the same name as the given module, but with "Used" appended.
The main module and the spec were both included, but `VersionKit` was not modified, so it didn't need a new name.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'usable'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ridiculous/usable.

