# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Run tests with coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task[:test].invoke
end

task default: :test

desc "Build and install the gem locally"
task install: :build do
  sh "gem install pkg/ask-computer-#{Ask::Computer::VERSION}.gem"
end

desc "Push the gem to RubyGems"
task release: :build do
  sh "gem push pkg/ask-computer-#{Ask::Computer::VERSION}.gem"
end
