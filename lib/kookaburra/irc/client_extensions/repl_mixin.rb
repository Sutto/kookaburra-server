module Kookaburra
  module IRC
    module ClientExtensions
      # Default Responses.
      module ReplMixin
        
        def repl_welcome
          client = "#{@nick}!#{@user}@#{@peername}"
          reply :numeric, Replies::RPL_WELCOME, @nick, "Welcome to Cockatoo - #{client}"
        end

        def repl_yourhost
          reply :numeric, Replies::RPL_YOURHOST, @nick, "Your host is #{@host}, running version #{@ver}"
        end

        def repl_created
          reply :numeric, Replies::RPL_CREATED, @nick, "This server was created #{@starttime}"
        end

        def repl_myinfo
          reply :numeric, Replies::RPL_MYINFO, @nick, "#{@host} #{@ver} #{@serv.usermodes} #{@serv.channelmodes}"
        end

        def repl_bounce(sever, port)
          reply :numeric, Replies::RPL_BOUNCE ,"Try server #{server}, port #{port}"
        end

        def repl_ison
          #XXX TODO
          reply :numeric, Replies::RPL_ISON,"notimpl"
        end

        def repl_away(nick, msg)
          reply :numeric, Replies::RPL_AWAY, nick, msg
        end

        def repl_unaway
          reply :numeric, Replies::RPL_UNAWAY, @nick,"You are no longer marked as being away"
        end

        def repl_nowaway
          reply :numeric, Replies::RPL_NOWAWAY, @nick,"You have been marked as being away"
        end

        def repl_motd
          reply :numeric, Replies::RPL_MOTDSTART,'', "MOTD"
          (@@motd_lines ||= File.read(File.join(Kookaburra.root, "data/motd")).split("\n")).each do |l|
            reply :numeric, Replies::RPL_MOTD,'', l
          end
          reply :numeric, Replies::RPL_ENDOFMOTD,'', "End of /MOTD command."
        end

        def repl_mode
        end
        
      end
    end
  end
end