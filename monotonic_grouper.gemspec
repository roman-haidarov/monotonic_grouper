Gem::Specification.new do |spec|
  spec.name          = "monotonic_grouper"
  spec.version       = "1.0.2"
  spec.authors       = ["Roman Hajdarov"]
  spec.email         = ["romnhajdarov@gmail.com"]

  spec.summary       = %q{Fast C extension for grouping monotonic sequences}
  spec.description   = %q{Groups consecutive monotonic sequences in arrays into ranges. Supports any Comparable type with succ method.}
  spec.homepage      = "https://github.com/roman-haidarov/monotonic_grouper"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "ext/**/*", "README.md"]
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/monotonic_grouper/extconf.rb"]

  spec.required_ruby_version = ">= 2.5.0"
end
