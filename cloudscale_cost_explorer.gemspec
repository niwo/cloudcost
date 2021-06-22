Gem::Specification.new do |s|
  s.name = "cloudscale_cost_explorer"
  s.version = "0.0.1"
  s.homepage = "https://gitlab.puzzle.ch/nwolfgramm/cloudscale_cost_explorer"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nik Wolfgramm"]
  s.date = %q{2021-06-21}
  s.description = %q{Calculate cloudscale.ch server costs from your actual deployment}
  s.email = %q{wolfgramm@puzzle.ch}
  s.files = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 1.9.3'
  s.summary = %q{cloudscale.ch cost explorer}
  s.executables = %w(cloudscale_cost_explorer)
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.license = 'MIT'

  s.add_dependency('excon')
  s.add_dependency('tty-spinner')
  s.add_dependency('terminal-table')
end