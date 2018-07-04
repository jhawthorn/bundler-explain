
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bundler/explain/version"

Gem::Specification.new do |spec|
  spec.name          = "bundler-explain"
  spec.version       = Bundler::Explain::VERSION
  spec.authors       = ["John Hawthorn"]
  spec.email         = ["john@hawthorn.email"]

  spec.summary       = %q{Explains bundle update conflicts}
  spec.description   = %q{Gives better explanations of conflicts when running bundle update.}
  spec.homepage      = "https://github.com/jhawthorn/bundler-explain"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1.16"
  spec.add_dependency "pub_grub"

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
