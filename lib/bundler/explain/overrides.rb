require 'pub_grub'
require "bundler/explain/source"

Bundler::Resolver.prepend(Module.new do
  def version_conflict_message(e)
    definition = Bundler.definition
    requirements = definition.send(:expanded_dependencies)
    platform = @platforms.first # probably wrong

    source = Bundler::Explain::Source.new(
      resolver: self,
      requirements: requirements,
      platform: platform
    )

    solver = PubGrub::VersionSolver.new(source: source)

    begin
      solver.solve
    rescue PubGrub::SolveFailure => e
      # Great. PubGrub found the source of the conflict.
      # Let's report it to the user.
      return <<MSG
Bundler could not find compatible versions of all gems.

This explanation comes from bundler-explain, please report any issues to
https://github.com/jhawthorn/bundler-explain/issues

#{e.explanation}
MSG
    rescue
      # If PubGrub fails for any reason, ignore it
    end

    # We weren't able to find the cause using PubGrub.
    # Fall back to bundler's built-in error reporting.
    super
  end
end)
