$LOAD_PATH.unshift "./lib"
require 'bundler/explain'
require 'pub_grub'

ENV['DEBUG'] = 'true'

Bundler.ui = Bundler::UI::Shell.new
PubGrub.logger.level = Logger::DEBUG

source = Bundler::Explain::Source.new
solver = PubGrub::VersionSolver.new(source: source)
result = solver.solve

pp result
