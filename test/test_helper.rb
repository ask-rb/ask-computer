# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
# Monorepo sibling gems resolve via Bundler local overrides; fallback to local lib paths.
%w[ask-core ask-tools].each do |gem_name|
  path = File.expand_path("../../#{gem_name}/lib", __dir__)
  $LOAD_PATH.unshift(path) if File.directory?(path)
end

require "ask-computer"
require "minitest/autorun"
require "mocha/minitest"
