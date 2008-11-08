module Kookaburra
  module BaseExtension

    def logger
      @@logger ||= setup_logger!
    end

    def verbose?
      !!Kookaburra::Settings.verbose
    end
    
    def started_at; @@started_at ||= Time.now.to_s; end

    def root
      @@root || File.expand_path(File.join(File.dirname(__FILE__), ".."))
    end

    def root=(path)
      @@root = path
    end

    def message_server; @@messsage_server ||= MessageServer.start; end

    # Initialization

    def setup_logger!
      @@logger = Kookaburra::Logger.new(Kookaburra::Settings.log_level.to_sym, self.verbose?)
    end

    def setup_traps!
      trap("INT") do 
          Kookaburra.message_server.dump
          Kookaburra.logger.close!
          system("kill -9 #{$$}")
      end
    end
    
    def boot_at(base_path)
      Kookaburra.root = base_path
      Kookaburra.setup!
      Kookaburra.logger.info "Starting Kookaburra"
      # Access the message server.
      Kookaburra.message_server
      Kookaburra.run!
    end

    def setup!
      require File.join(self.root, 'config/settings')
      Kookaburra::Options.parse!
      @@started_at = Time.now.to_s
      Kookaburra::Stores.channels["#all"] = Kookaburra::IRC::CatchAll.new
      setup_logger!
      setup_traps!
    end

    def run!
      begin
        EventMachine::run do
          EventMachine::add_periodic_timer(15) do
            Kookaburra::IRC::Server.ping_all
          end
          EventMachine::start_server "0.0.0.0", Kookaburra::Settings.port, Kookaburra::IRC::Server
        end
      rescue Exception => e
        Kookaburra.logger.debug_exception e
      end
    end

  end
end
