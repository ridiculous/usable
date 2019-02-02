# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'usable/version'

Gem::Specification.new do |spec|
  spec.name          = "usable"
  spec.version       = Usable::VERSION
  spec.authors       = ["Ryan Buckley"]
  spec.email         = ["arebuckley@gmail.com"]

  spec.summary       = %q{Mounts and configures modules}
  spec.description   = %q{Usable provides an elegant way to mount and configure your modules}
  spec.homepage      = "https://github.com/ridiculous/usable"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").keep_if { |f| f =~ /usable/ and f !~ /spec\// }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '>= 3.2', '< 4'
  # spec.add_development_dependency 'rspec-scaffold', '>= 1.0', '< 2'
end
