# Usable

Rack style mixins for Ruby objects. Mount your modules like you mean it!

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
>> Model.new.respond_to? :destroy_version     
=> false
```
You can also define a custom module within the "usable" module that defines the methods which can be configured to be
extended or excluded. The module must be named "UsableSpec" and be defined one level inside the namespace. For example:

```ruby
module VersionKit
  module UsableSpec
    def version
      "spec version included"
    end
  end
  
  def version
    "this version not included"
  end
  
  def self.included(base)
    puts base.usable_config.available_methods[:version].bind(self).call
  end
end

>> Example = Class.new.extend Usable
=> Example
>> Example.usable VersionKit
spec version included
=> Example
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'usable'
```

Or install it yourself as:

    $ gem install usable

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/usable.

