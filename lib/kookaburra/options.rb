module Kookaburra
  class Options
    def self.parse!
      opts = Trollop::options do
        version Kookaburra::VERSION.to_s
        banner ["A Simplistic IRCD in ruby",  "Usage: ./script/server [options]"].join("\n")
        opt :verbose, "Log output to STDOUT", :default => !!(Kookaburra::Settings.verbose || false)
        opt :level,   "What log level to use", :default => Kookaburra::Settings.log_level.to_s, :type => :string
      end
      Kookaburra::Settings.verbose   = opts[:verbose]
      Kookaburra::Settings.log_level = opts[:level].to_sym
    end
  end
end