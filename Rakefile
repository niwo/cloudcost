# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[rubocop]


DOCKER_REGISTRY = "registry.puzzle.ch/puzzle/cloudcost"

desc "Build the docker image and tag it with the current version."
task :docker_build do
  puts command = "docker build -t #{DOCKER_REGISTRY}:#{Cloudcost::VERSION} ."
  puts `#{command}`
end

desc "Push the newest docker image."
task :docker_push do
  puts command = "docker push #{DOCKER_REGISTRY}:#{Cloudcost::VERSION}"
  puts `#{command}`
end
