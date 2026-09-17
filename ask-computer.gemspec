# frozen_string_literal: true

require_relative "lib/ask/computer/version"

Gem::Specification.new do |spec|
  spec.name = "ask-computer"
  spec.version = Ask::Computer::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "Computer use for the ask-rb ecosystem"
  spec.description = "Drive desktop apps in the background via Cua Driver — " \
                     "screenshots, clicks, typing, sandboxed VMs, and encrypted " \
                     "Computer History. Wraps Cua's MCP tools as Ask::Tool " \
                     "subclasses and ships a bundled computer.use_computer skill."
  spec.homepage = "https://github.com/ask-rb/ask-computer"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) { Dir["lib/**/*", "exe/**/*", "LICENSE", "README.md", "CHANGELOG.md"] }
  spec.require_paths = ["lib"]
  spec.bindir = "exe"
  spec.executables = ["ask-computer"]

  spec.add_dependency "ask-core", ">= 0.12.0"
  spec.add_dependency "ask-mcp", ">= 0.5.0"
  spec.add_dependency "ask-tools", ">= 0.6.2"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "mocha", "~> 3.1"
  spec.add_development_dependency "rake", "~> 13.0"
end
