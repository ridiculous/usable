$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'pathname'
require 'usable'
begin
  require "object_tracker"
rescue LoadError
  nil
end
begin
  require "byebug"
rescue LoadError
  nil
end
Usable.logger.level = 0
RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  # config.filter_run focus: true
end
