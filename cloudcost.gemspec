# frozen_string_literal: true

require "English"
require_relative "lib/cloudcost/version"

Gem::Specification.new do |s|
  s.name = "cloudcost"
  s.version = Cloudcost::VERSION
  s.homepage = "https://gitlab.puzzle.ch/nwolfgramm/cloudcost"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nik Wolfgramm"]
  s.description = "Calculate cloudscale.ch server costs from your actual deployment"
  s.email = "wolfgramm@puzzle.ch"
  s.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.7"
  s.summary = "cloudscale.ch cost explorer"
  s.executables = %w[cloudcost]
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.license = "MIT"

  s.add_dependency("excon", "~> 0.82.0")
  s.add_dependency("parseconfig", "~> 1.1.0")
  s.add_dependency("terminal-table", "~> 3.0.1")
  s.add_dependency("thor", "~> 1.1.0")
  s.add_dependency("tty-spinner", "~> 0.9.3")
end
