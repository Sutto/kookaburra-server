["handle", "repl", "send"].each do |name|
  require File.join(File.dirname(__FILE__), "client_extensions/#{name}_mixin")
end

module Kookaburra
  module IRC
    class Client
      CHANNEL = /^[#\$&]+/

      attr_reader :nick, :user, :realname, :channels, :state, :server

      def initialize(serv)
        @server = serv
        @serv = serv
        @channels = []
        @peername = peer
        @welcomed = false
        @nick_tries = 0
        @state = {}
        Kookaburra.logger.info "Initializing connection from '#{@peername}'"
      end

      def host
        return @peername
      end

      def userprefix
        return @usermsg
      end

      def ready
        #check for nick and pass
        return (!@pass.nil? && !@nick.blank?)
      end

      def peer
        sockaddr = server.get_peername
        begin
          return Socket.getnameinfo(sockaddr, Socket::NI_NAMEREQD).first
        rescue 
          return Socket.getnameinfo(sockaddr).first
        end
      end

      def mode
        return @mode
      end

      def names(channel)
        return Kookaburra::Stores.channels[channel].nicks
      end
      
      def reply(method, *args)
        case method
        when :raw
          arg = *args
          raw arg
        when :ping
          host = *args
          raw "PING :#{host}"
        when :pong
          msg = *args
          # according to rfc 2812 the PONG must be of
          #PONG csd.bu.edu tolsun.oulu.fi
          # PONG message from csd.bu.edu to tolsun.oulu.fi
          # ie no host at the begining
          raw "PONG #{@host} #{@peername} :#{msg}"
        when :join
          user,channel = args
          raw "#{user} JOIN :#{channel}"
        when :part
          user,channel,msg = args
          raw "#{user} PART #{channel} :#{msg}"
        when :quit
          user,msg = args
          raw "#{user} QUIT :#{msg}"
        when :privmsg
          usermsg, channel, msg = args
          raw "#{usermsg} PRIVMSG #{channel} :#{msg}"
        when :notice
          usermsg, channel, msg = args
          raw "#{usermsg} NOTICE #{channel} :#{msg}"
        when :topic
          usermsg, channel, msg = args
          raw "#{usermsg} TOPIC #{channel} :#{msg}"
        when :nick
          nick = *args
          raw "#{@usermsg} NICK :#{nick}"
        when :mode
          nick, rest = args
          raw "#{@usermsg} MODE #{nick} :#{rest}"
        when :numeric
          numeric,msg,detail = args
          server = Kookaburra::Settings.host_name
          raw ":#{server} #{'%03d'%numeric} #{@nick} #{msg} :#{detail}"
        end
      end

      def raw(arg, abrt=false)
        begin
        Kookaburra.logger.debug ">>> #{arg}"
        @server.send_data arg.chomp + "\r\n" if !arg.nil?
        rescue Exception => e
          Kookaburra.logger.debug_exception e
          handle_abort
          raise e if abrt
        end
      end
      
      # Include all of the non-basic functionality.
      include Kookaburra::IRC::ClientExtensions::HandleMixin
      include Kookaburra::IRC::ClientExtensions::ReplMixin
      include Kookaburra::IRC::ClientExtensions::SendMixin
      
    end
  end
end