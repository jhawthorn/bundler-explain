module Bundler
  module Explain
    class Source
      def initialize
        @definition = Bundler.definition(true)
        @requirements = @definition.send(:expanded_dependencies)
        build_resolver

        # This is probably wrong
        platform = @definition.platforms.first

        @specs_by_name = Hash.new do |h, name|
          @resolver.search_for(Bundler::DepProxy.new(Gem::Dependency.new(name), platform)).reverse
        end

        @package_by_name = Hash.new do |h, name|
          h[name] =
            PubGrub::Package.new(name) do |package|
              @specs_by_name[name].each do |spec_group|
                package.add_version spec_group.version.to_s
              end
            end
        end
      end

      def incompatibilities_for(version)
        if version == PubGrub::Package.root_version
          # It's root! Return our requirements
          @requirements

          source_constraint = PubGrub::VersionConstraint.exact(version)
          source_term = PubGrub::Term.new(source_constraint, true)

          @requirements.map do |dependency|
            target_constraint = constraint_for_dep(dependency)
            target_term = PubGrub::Term.new(target_constraint, false)

            PubGrub::Incompatibility.new([source_term, target_term], cause: :dependency)
          end
        else
          specs = @specs_by_name[version.package.name]
          spec = specs.detect { |s| s.version.to_s == version.name }
          sorted_specs = specs.sort_by(&:version)
          raise "can't find spec" unless spec

          dependencies = spec.dependencies_for_activated_platforms

          dependencies.map do |dependency|
            target_constraint = constraint_for_dep(dependency)
            target_term = PubGrub::Term.new(target_constraint, false)

            low = high = sorted_specs.index(spec)

            loop do
              high += 1
              break if high >= sorted_specs.length
              break unless sorted_specs[high].dependencies_for_activated_platforms.include?(dependency)
            end
            high -= 1

            loop do
              low -= 1
              break if low < 0
              break unless sorted_specs[low].dependencies_for_activated_platforms.include?(dependency)
            end
            low += 1

            if low == high
              source_constraint = PubGrub::VersionConstraint.exact(version)
            else
              package = version.package
              low_version = sorted_specs[low].version
              high_version = sorted_specs[high].version

              source_constraint = PubGrub::VersionConstraint.new(package, [">= #{low_version}", "<= #{high_version}"])
            end

            source_term = PubGrub::Term.new(source_constraint, true)

            PubGrub::Incompatibility.new([source_term, target_term], cause: :dependency)
          end
        end
      end

      private

      def constraint_for_dep(dep_proxy)
        dep = dep_proxy.dep
        package = @package_by_name[dep.name]

        # This is awful. We should try to reuse Gem::Requirement
        requirement = dep.requirement.to_s.split(", ")

        PubGrub::VersionConstraint.new(package, requirement)
      end

      def build_resolver
        # awful, horrible hacks
        @resolver = @definition.instance_eval do
          @remote = true
          sources.remote!

          platforms = Set.new(platforms)
          base = Bundler::SpecSet.new([])
          Bundler::Resolver.new(index, source_requirements, base, gem_version_promoter, additional_base_requirements_for_resolve, platforms)
        end

        requirements = @requirements
        # Because we don't #start, we need to hack some things in
        @resolver.instance_eval do
          @prerelease_specified = {}
          requirements.each {|dep| @prerelease_specified[dep.name] ||= dep.prerelease? }

          verify_gemfile_dependencies_are_found!(requirements)
        end
      end
    end
  end
end
