# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Xavier Shay"]
  gem.email         = ["contact@xaviershay.com"]
  gem.description   =
    %q{yeah}
  gem.summary       = %q{
    testing library
  }
  gem.homepage      = "http://github.com/xaviershay/xspec"

  gem.executables   = []
  gem.required_ruby_version = '>= 2.1.0'
  gem.files         = Dir.glob("{spec,lib}/**/*.rb") + %w(
                        README.md
                        xspec.gemspec
                      )
  gem.test_files    = Dir.glob("spec/**/*.rb")
  gem.name          = "xspec"
  gem.require_paths = ["lib"]
  gem.bindir        = "bin"
  gem.executables  << "xspec"
  gem.license       = "Apache 2.0"
  gem.version       = "0.2.0"
  gem.has_rdoc      = false
end
