$LOAD_PATH.unshift "./lib"
require 'bundler/explain'
require 'pub_grub'

ENV['DEBUG'] = 'true'

Bundler.ui = Bundler::UI::Shell.new
PubGrub.logger.level = Logger::DEBUG

definition = Bundler.definition(true)
requirements = definition.send(:expanded_dependencies)
platform = definition.platforms.first # probably wrong
resolver = definition.instance_eval do
  @remote = true
  sources.remote!

  platforms = Set.new(platforms)
  base = Bundler::SpecSet.new([])
  Bundler::Resolver.new(index, source_requirements, base, gem_version_promoter, additional_base_requirements_for_resolve, platforms)
end

# Because we don't #start, we need to hack some things in
resolver.instance_eval do
  @prerelease_specified = {}
  requirements.each {|dep| @prerelease_specified[dep.name] ||= dep.prerelease? }

  verify_gemfile_dependencies_are_found!(requirements)
end

source = Bundler::Explain::Source.new(
  requirements: requirements,
  resolver: resolver,
  platform: platform
)

solver = PubGrub::VersionSolver.new(source: source)
result = solver.solve

pp result
