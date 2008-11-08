module Kookaburra
  module IRC
    module ClientExtensions
      # Butt ugly handles.
      module HandleMixin
        CHANNEL = /^[#\$&]+/
        
        def handle_newconnect(nick)
          @alive = true
          @nick = nick
          @host = Kookaburra::Settings.host_name
          @ver = Kookaburra::VERSION
          @starttime = Kookaburra.started_at
          send_welcome if !@user.nil?
        end
        
        def handle_pass(s)
          @pass = s
        end

        def handle_nick(s)
          Kookaburra.logger.info "Attemping to set nick to #{s}"
          if !s.blank? && Kookaburra::Stores.users[s].nil?
            userlist = {}
            if @nick.nil?
              handle_newconnect(s)
            else
              userlist[s] = self if self.nick != s
              Kookaburra::Stores.users.delete(@nick)
              @nick = s
            end
            Kookaburra::Stores.users[self.nick] = self
            #send the info to the world
            #get unique users.
            @channels.each  do |c|
              Kookaburra::Stores.channels[c].each_user do |u|
                userlist[u.nick] = u
              end
            end
            userlist.values.each do |user|
              user.reply :nick, s
            end
            @usermsg = ":#{@nick}!~#{@user}@#{@peername}"
            Kookaburra.message_server.unviewed_for(self.nick).each do |message|
              reply :privmsg, ":#{message.from}!~unknown@cockatoo-server-queue", self.nick, message.content
            end
            Kookaburra.message_server.mark_as_viewed!(self.nick)
          else
            #check if we are just nicking ourselves.
            unless Kookaburra::Stores.users[s] == self
              Kookaburra.logger.info "Nick #{s} is taken, responding."
              reply :numeric, Replies::ERR_NICKNAMEINUSE, "* #{s} ","Nickname is already in use."
              @nick_tries += 1
              if @nick_tries > Kookaburra::Settings.max_nick_tries
                Kookaburra.logger.info "Kicking user #{s} after #{@nick_tries} failed nick attempts"
                handle_abort
              end
              return
            end
          end
          @nick_tries = 0
        end

        def handle_user(user, mode, unused, realname)
          @user = user
          @mode = mode
          @realname = realname
          @usermsg = ":#{@nick}!~#{@user}@#{@peername}"
          send_welcome if !@nick.nil?
        end
        
        def handle_join(channels)
          #return if @nick.blank?
          channels.split(/,/).each do |ch|
            c = ch.strip
            if c !~ CHANNEL
              send_nochannel(c)
              Kookaburra.logger.info "Attemping to join invalid channel name '#{c}'"
              return
            end
            channel = (Kookaburra::Stores.channels[c] ||= Channel.new(c))
            if channel.join(self)
              send_topic(c)
              send_nameslist(c)
              @channels << c
            else
              Kookaburra.logger.info "User already joined #{c}"
            end
          end
        end

        def handle_ping(pingmsg, rest)
          reply :pong, pingmsg
        end

        def handle_pong(srv)
          Kookaburra.logger.info "Got pong: #{srv}"
          # If we have more than one outstanding ping,
          # We decrease the outstanding count.
          Kookaburra::Stores.pings[self.nick] -= 1 if Kookaburra::Stores.pings[self.nick] > 0
          Kookaburra.logger.info "Ping count for #{self.nick} - #{Kookaburra::Stores.pings[self.nick]}"
        end

        def handle_privmsg(target, msg)
          #return if @nick.blank?
          viewed = true
          case target.strip
          when "#all"
            return # Ignore messages from all
          when CHANNEL
            channel= Kookaburra::Stores.channels[target]
            if !channel.nil?
              channel.privatemsg(msg, self)
            else
              send_nonick(target)
            end
          else
            user = Kookaburra::Stores.users[target]
            if !user.nil?
              if !user.state[:away].nil?
                repl_away(user.nick,user.state[:away])
              end
              user.reply :privmsg, self.userprefix, user.nick, msg
            else
              viewed = false
            end
          end
          begin
            Kookaburra.message_server.append_message(self.nick, target.strip, msg, viewed)
          rescue Exception => e
            Kookaburra.logger.debug_exception e
          end
        end

        def handle_notice(target, msg)
          #return if @nick.blank?
          case target.strip
          when CHANNEL
            channel= Kookaburra::Stores.channels[target]
            if !channel.nil?
              channel.notice(msg, self)
            else
              send_nonick(target)
            end
          else
            user = Kookaburra::Stores.users[target]
            if !user.nil?
              user.reply :notice, self.userprefix, user.nick, msg
            else
              send_nonick(target)
            end
          end
        end

        def handle_part(channel, msg)
          if Kookaburra::Stores.channels.channels.include? channel
            if Kookaburra::Stores.channels[channel].part(self, msg)
              @channels.delete(channel)
            else
              send_notonchannel channel
            end
          else
            send_nochannel channel
          end
        end

        def handle_quit(msg)
          #do this to avoid double quit due to 2 threads.
          return if !@alive
          @alive = false
          @channels.each do |channel|
            Kookaburra::Stores.channels[channel].quit(self, msg)
          end
          Kookaburra::Stores.users.delete(self.nick)
          Kookaburra.logger.info "#{self.nick} quit w/ message: #{msg}"
          @server.close_connection
        end

        def handle_topic(channel, topic)
          #return if @nick.blank?
          Kookaburra.logger.info  "handle topic for #{channel}: #{topic}"
          if topic.nil? or topic =~ /^ *$/
            send_topic(channel)
          else
            begin
              Kookaburra::Stores.channels[channel].topic(topic,self)
            rescue Exception => e
              Kookaburra.logger.debug_exception e
            end
          end
        end

        def handle_away(msg)
          Kookaburra.logger.info "Away w/ message: #{msg}"
          if msg.nil? or msg =~ /^ *$/
            @state.delete(:away)
            repl_unaway
          else
            @state[:away] = msg
            repl_nowaway
          end
        end

        def handle_list(channel)
          reply :numeric, Replies::RPL_LISTSTART
          case channel.strip
          when /^#/
            channel.split(/,/).each do |cname|
              c = Kookaburra::Stores.channels[cname.strip]
              reply :numeric, Replies::RPL_LIST, c.name, c.topic if c
            end
          else
            Kookaburra::Stores.channels.each_channel do |c|
              reply :numeric, Replies::RPL_LIST, c.name, c.topic
            end
          end
          reply :numeric, Replies::RPL_LISTEND
        end

        def handle_whois(target,nicks)
          #ignore target for now.
          return reply(:numeric, Replies::RPL_NONICKNAMEGIVEN, "", "No nickname given") if nicks.strip.length == 0
          nicks.split(/,/).each do |nick|
            nick.strip!
            user = Kookaburra::Stores.users[nick]
            if user
              reply :numeric, Replies::RPL_WHOISUSER, "#{user.nick} #{user.user} #{user.host} *", "#{user.realname}"
              reply :numeric, Replies::RPL_WHOISCHANNELS, user.nick, "#{user.channels.join(' ')}"
              repl_away user.nick, user.state[:away] if !user.state[:away].nil?
              reply :numeric, Replies::RPL_ENDOFWHOIS, user.nick, "End of /WHOIS list"
            else
              return send_nonick(nick) 
            end
          end
        end

        def handle_names(channels, server)
          channels.split(/,/).each {|ch| send_nameslist(ch.strip) }
        end

        def handle_who(mask, rest)
          channel = Kookaburra::Stores.channels[mask]
          hopcount = 0
          if channel.nil?
            #match against all users
            Kookaburra::Stores.users.each_user do |user|
              reply :numeric, Replies::RPL_WHOREPLY ,
                "#{user.channels[0]} #{user.userprefix} #{user.host} #{Kookaburra::Settings.host_name} #{user.nick} H" , 
                "#{hopcount} #{user.realname}" if File.fnmatch?(mask, "#{user.host}.#{user.realname}.#{user.nick}")
            end
            reply :numeric, Replies::RPL_ENDOFWHO, mask, "End of /WHO list."
          else
            #get all users in the channel
            channel.each_user do |user|
              reply :numeric, Replies::RPL_WHOREPLY ,
                "#{mask} #{user.userprefix} #{user.host} #{Kookaburra::Settings.host_name} #{user.nick} H" , 
                "#{hopcount} #{user.realname}"
            end
            reply :numeric, Replies::RPL_ENDOFWHO, mask, "End of /WHO list."
          end
        end

        def handle_mode(target, rest)
          reply :mode, target, rest
        end

        def handle_userhost(nicks)
          info = []
          nicks.split(/,/).each do |nick|
            user = Kookaburra::Stores.users[nick]
            info << user.nick + '=-' + user.nick + '@' + user.peer
          end
          reply :numeric, Replies::RPL_USERHOST,"", info.join(' ')
        end

        def handle_reload(password)
        end

        def handle_abort
          handle_quit('no can has power')
        end

        def handle_version
          reply :numeric, Replies::RPL_VERSION, "v#{Kookaburra::VERSION} Kookaburra", ""
        end

        def handle_eval(s)
          #reply :raw, eval(s)
        end

        def handle_unknown(s)
          Kookaburra.logger.warn "Unkwown command: #{s}"
          reply :numeric, Replies::ERR_UNKNOWNCOMMAND,s, "Unknown command"
        end

        def handle_connect
          reply :raw, "NOTICE AUTH :Kookaburra v#{Kookaburra::VERSION} initialized, welcome."
        end
        
      end
    end
  end
end