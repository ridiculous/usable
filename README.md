# Usable [![Gem Version](https://badge.fury.io/rb/usable.svg)](http://badge.fury.io/rb/usable) [![Build Status](https://travis-ci.org/ridiculous/usable.svg)](https://travis-ci.org/ridiculous/usable) [![Code Climate](https://codeclimate.com/github/ridiculous/usable/badges/gpa.svg)](https://codeclimate.com/github/ridiculous/usable)

An elegant way to mount and configure your modules. Usable gives you control over which methods are included, and a simple
interface to help you call dynamic methods with confidence.

```ruby
module VersionMixin
  def save_version
    "Saving up to #{self.class.usable_config.max_versions} versions to #{self.class.usable_config.table_name}"
  end

  def destroy_version
    "Deleting versions from #{self.class.usable_config.table_name}"
  end
end

class Model
  extend Usable

  usable VersionMixin, only: :save_version do |config|
    config.max_versions = 10
    config.table_name = 'custom_versions'
  end

  def save
    self.class.usable_method(self, :save_version).call
  end
end

model = Model.new
model.save_version     # => "Saving up to 10 versions to custom_versions"
model.destroy_version  # => NoMethodError: undefined method `destroy_version' for #<Model:...
```
`Model` now has a `#save_versions` method but no `#destroy_version` method. Usable has effectively mixed in the given module
using `include`. However, Ruby 2+ now has the ability to `prepend` modules as well. Usable supports this ability with
the `:method` option:

```ruby
Model.usable VersionMixin, method: 'prepend'
```

Usable reserves the `:only` and `:method` options for these kinds of customizations. If you
really need to define config settings on the target class with the same name as those, you can simply define them in the block:

```ruby
Model.usable VersionMixin, only: [:save_version] do |config|
  config.only = "Will be set on `Model.usable_config.only`"
end
```

## Confidently calling methods

We should all be writing [confident code](http://www.confidentruby.com/), which is why you might want to call configurable
methods through the `usable_method` class level function. Methods passed in with the `:only` option
will _always_ return `nil` when called. Thus, the confidence.

Here's the same example as above, rewritten to call methods through the Usable interface:

```ruby
Model.usable_method(model, :save_version).call    # => "Saving up to 10 versions to custom_versions"
Model.usable_method(model, :destroy_version).call # => nil
```

## Separate the _included_ module from the _configurable_ methods

Sometimes you want to define methods on a module and have them always be included. To do this, define a module named 
`UsableSpec` in the scope of the module you are mounting. `Usable` will detect this and use he "spec" module to configure 
the available methods. Any naming conflicts will be resolved by giving precedence to the parent module.

For example:

```ruby
module Mixin
  def name
    "defined by Mixin"
  end

  def from_mixin
    "always here"
  end

  # @description Usable will apply the :only option to just the methods defined by this module
  module UsableSpec
    def from_spec
      "can be excluded"
    end

    def name
      "defined by UsableSpec"
    end
  end
end

class Example
  extend Usable
  usable Mixin, only: [:name, :from_spec]
end

Example.new.from_spec   # => "can be excluded"
Example.new.from_mixin  # => "always here"
Example.new.name        # => "defined by Mixin"
Example.ancestors       # => [Example, Mixin, Example::MixinUsableSpecUsed, Object, Kernel, BasicObject] (ruby -v 2.3.0)
```

Notice that Usable assigns the modified module to a constant with the same name as the given module, but with "Used" appended.
The main module and the spec were both included, but `Mixin` was not modified, so it didn't need a new name.

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

