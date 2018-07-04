require "bundler"
require "bundler/explain/version"
require "bundler/explain/source"

module Bundler
  module Explain
    def self.register
      Bundler::Plugin.add_hook('before-install-all') do |dependencies|
        require "bundler/explain/overrides"
      end
    end
  end
end
