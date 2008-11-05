module Kookaburra
  class Options
    def self.parse!
      CoolOptions.parse!("[options]") do |o|
          o.desc 'Boots up the irc server.'
          o.on "verbose",   "Log output to STDOUT.", (Kookaburra::Settings.verbose || false)
          o.on "loglevel", "Set the log level",     :info

          o.after do |r|
            Kookaburra::Settings.verbose   = r.verbose
            Kookaburra::Settings.log_level = r.log_level || :info
          end
        end
    end
  end
end