module Kookaburra
  module IRC
    module ClientExtensions
      module SendMixin
        
        def send_welcome
          if !@welcomed
            repl_welcome
            repl_yourhost
            repl_created
            repl_myinfo
            repl_motd
            repl_mode
            # Force the user to join #all
            reply :join, @usermsg, "#all"
            reply :join, @usermsg, "#general"
            @welcomed = true
          end
        end

        def send_nonick(nick)
          reply :numeric, Replies::ERR_NOSUCHNICK, nick, "No such nick/channel"
        end

        def send_nochannel(channel)
          reply :numeric, Replies::ERR_NOSUCHCHANNEL, channel, "That channel doesn't exist"
        end

        def send_notonchannel(channel)
          reply :numeric, Replies::ERR_NOTONCHANNEL, channel, "Not a member of that channel"
        end

        def send_topic(channel)
          if Kookaburra::Stores.channels[channel]
            reply :numeric, Replies::RPL_TOPIC,channel, Kookaburra::Stores.channels[channel].topic.to_s
          else
            send_notonchannel channel
          end
        end

        def send_nameslist(channel)
          c =  Kookaburra::Stores.channels[channel]
          if c.nil?
            Kookaburra.logger.info "No known channel '#{channel}' when getting names list"
            return 
          end
          names = []
          c.each_user do |user|
            names << c.mode(user) + user.nick if user.nick
          end
          reply :numeric, Replies::RPL_NAMREPLY,"= #{c.name}","#{names.join(' ')}"
          reply :numeric, Replies::RPL_ENDOFNAMES,"#{c.name} ","End of /NAMES list."
        end

        def send_ping
          if Kookaburra::Stores.pings[self.nick] > Kookaburra::Settings.max_pings
            Kookaburra.logger.fatal "#{self.nick} hasn't responded to pings."
            self.server.close_connection
          else
            Kookaburra::Stores.pings[self.nick] += 1
            reply :ping, Kookaburra::Settings.host_name
          end
        end
        
      end
    end
  end
end