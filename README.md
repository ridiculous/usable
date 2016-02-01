# Usable

Rack style mixins for Ruby objects. Mount your modules like you mean it!

```ruby
class Model
  extend Usable
  
  module Versionable
    def not_defined_on_parent
        puts 'should be nil'
    end
    
    def versions
      "Saving #{self.class.config.max_versions} versions to #{self.class.config.table_name}"
    end
  end

  # with options hash
  use Versionable, table_name: 'custom_versions', only: :versions

  # or with block
  use Versionable do |config|
    config.max_versions = 10
  end
end

Model.config.table_name #=> 'custom_versions'
Model.new.versions #=> "Saving 10 versions to custom_versions"
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

