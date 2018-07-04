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

        @sorted_specs_by_name = Hash.new do |h, name|
          h[name] = @specs_by_name[name].sort_by(&:version)
        end

        @package_by_name = Hash.new do |h, name|
          h[name] =
            PubGrub::Package.new(name) do |package|
              @specs_by_name[name].each do |spec_group|
                package.add_version spec_group.version.to_s
              end
            end
        end

        @deps_by_spec = Hash.new do |h, s|
          h[s] = s.dependencies_for_activated_platforms.map do |dep|
            [dep.name, dep.requirement]
          end.to_h
        end
      end

      def incompatibilities_for(version)
        return enum_for(__method__, version) unless block_given?

        package = version.package

        if version == PubGrub::Package.root_version
          source_constraint = PubGrub::VersionConstraint.exact(version)
          source_term = PubGrub::Term.new(source_constraint, true)

          @requirements.each do |dependency|
            target_constraint = constraint_for_dep(dependency.name, dependency.dep.requirement)
            target_term = PubGrub::Term.new(target_constraint, false)

            yield PubGrub::Incompatibility.new([source_term, target_term], cause: :dependency)
          end
        else
          specs = @specs_by_name[version.package.name]
          spec = specs.detect { |s| s.version.to_s == version.name }
          raise "can't find spec" unless spec

          @deps_by_spec[spec].each do |dep_name, dep_requirement|
            # Default case
            target_constraint = constraint_for_dep(dep_name, dep_requirement)
            source_constraint = range_constraint(spec) do |near_spec|
              @deps_by_spec[near_spec][dep_name] == dep_requirement
            end
            yield dependency_incompatiblity(source_constraint, target_constraint)

            # Special case: exact dependencies (like rails 5.0.7 requires)
            # We want to add an extra loosened (semver-like) dependency in
            # addition to the exact dependency above.
            if dep_requirement.exact?
              dep_version = dep_requirement.requirements[0][1]
              if dep_version == spec.version
                derived_requirements(dep_version).each do |new_requirement|
                  next unless new_requirement === dep_version

                  target_constraint = constraint_for_dep(dep_name, new_requirement)
                  source_constraint = range_constraint(spec) do |near_spec|
                    near_dep = @deps_by_spec[near_spec][dep_name]

                    near_dep && near_dep.exact? && new_requirement === near_dep.requirements[0][1]
                  end

                  yield dependency_incompatiblity(source_constraint, target_constraint)
                end
              end
            end
          end
        end
      end

      private

      def derived_requirements(original_version)
        return enum_for(__method__, original_version) unless block_given?

        v = original_version
        s = original_version.segments

        yield Gem::Requirement.new(">= #{s[0]}.#{s[1]}.a", "< #{v.release}")
        yield Gem::Requirement.new(["~> #{s[0]}.#{s[1]}.0"])
        yield Gem::Requirement.new(["~> #{s[0]}.#{s[1]}.0.a"])
        yield Gem::Requirement.new(["~> #{s[0]}.0.a"])
      end

      def dependency_incompatiblity(source_constraint, target_constraint)
        source_term = PubGrub::Term.new(source_constraint, true)
        target_term = PubGrub::Term.new(target_constraint, false)
        PubGrub::Incompatibility.new([source_term, target_term], cause: :dependency)
      end

      def range_constraint(spec, &block)
        sorted_specs = @sorted_specs_by_name[spec.name]
        package = @package_by_name[spec.name]

        low, high = range_matching(sorted_specs, sorted_specs.index(spec), &block)
        constraint_between_specs(package, low && sorted_specs[low], high && sorted_specs[high])
      end

      def constraint_between_specs(package, low_spec, high_spec)
        low_version = low_spec && low_spec.version
        high_version = high_spec && high_spec.version

        if !low_spec && !high_spec
          PubGrub::VersionConstraint.any(package)
        elsif low_spec == high_spec
          PubGrub::VersionConstraint.exact(package.version(low_version.to_s))
        else
          low = ">= #{low_version}" if low_spec
          high = "<= #{high_version}" if high_spec
          PubGrub::VersionConstraint.new(package, [low, high].compact)
        end
      end

      def range_matching(sorted_list, index)
        low = high = index

        raise "range_matching started at non-matching index" unless yield(sorted_list[index])

        loop do
          high += 1
          if high >= sorted_list.length
            high = nil
            break
          end
          break unless yield(sorted_list[high])
        end

        loop do
          low -= 1
          if low < 0
            low = nil
            break
          end
          break unless yield(sorted_list[low])
        end

        [low && low + 1, high && high - 1]
      end

      def constraint_for_dep(name, requirement)
        package = @package_by_name[name]

        # This is awful. We should try to reuse Gem::Requirement
        requirement = requirement.to_s.split(", ")

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
