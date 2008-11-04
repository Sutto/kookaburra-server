class Kookaburra
  class << self
    
    def version; "0.1"; end
    
    def logger
      @@logger ||= setup_logger!
    end
    
    def verbose?
      @@verbose ||= false
    end
  
    def verbose=(value)
      @@verbose = !!value
    end
    
    def root
      @@root || File.expand_path(File.join(File.dirname(__FILE__), ".."))
    end
    
    def root=(path)
      @@root = path
    end
    
    def host_name
      @@host_name ||= Socket.gethostname.split(/\./).shift
    end
    
    def started_at; @@started_at ||= Time.now.to_s; end
    
    def max_nick_tries; 5; end
    
    # Initialization
    
    def setup_logger!
      log_level = :debug
      if ARGV.detect { |c| c.to_s =~ /^(\-\-log\-level(.*))/i }
        cmd = $1
        if cmd.include?("=")
          log_level = cmd.split("=", 2)[1].to_sym
        else
          log_level = ARGV[ARGV.index(cmd) + 1].to_sym
        end
      end
      @@logger ||= IRCLogger.new((log_level || :debug).to_sym, self.verbose?)
    end
  
    def setup_traps!
      trap("INT") do 
          $message_server.dump
          system("kill -9 #{$$}")
      end
    end
  
    def setup_verbosity!
      self.verbose = !ARGV.detect { |c| c =~ /-v/ }.nil? || false
    end
    
    def setup!
      @@started_at = Time.now.to_s
      setup_verbosity!
      setup_logger!
      setup_traps!
    end
    
    
  end
end