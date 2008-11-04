class IRCServer < EventMachine::Protocols::LineAndTextProtocol

    @@connections = []
    
    def connection_completed
      @@connections.delete self
    end
    
    include NetUtils
    def usermodes
        return "aAbBcCdDeEfFGhHiIjkKlLmMnNopPQrRsStUvVwWxXyYzZ0123459*@"
    end

    def channelmodes
        return "bcdefFhiIklmnoPqstv"
    end

    def post_init
      @client = IRCClient.new(self)
      @client.handle_connect
      @@connections << self
    end
    
    def receive_line(line)
      carp "Recieved line: #{line}"
      s = Time.now
      begin
        handle_client_input(line, @client)
      rescue Exception => e
        carp e
      end
      carp "Line processed in #{Time.now.to_f - s.to_f} seconds"
    end
    
    def connection_completed
      @client.handle_abort
    end

    def handle_client_input(input, client)
        carp "<-- #{input}"
        s = if input =~ PREFIX
                $1
            else
                input
            end
        carp "Processing line"
        case s
        when /^[ ]*$/
            return
        when /^PASS +(.+)$/i
            client.handle_pass($1.strip)
        when /^NICK +(.+)$/i
            client.handle_nick($1.strip) #done
        when /^USER +([^ ]+) +([0-9]+) +([^ ]+) +:(.*)$/i
            client.handle_user($1, $2, $3, $4) #done
        when /^USER +([^ ]+) +([0-9]+) +([^ ]+) +:*(.*)$/i
            #opera does this.
            client.handle_user($1, $2, $3, $4) #done
        when /^USER ([^ ]+) +[^:]*:(.*)/i
            #chatzilla does this.
            client.handle_user($1, '', '', $3) #done
        when /^JOIN +(.+)$/i
            client.handle_join($1) #done
        when /^PING +([^ ]+) *(.*)$/i
            client.handle_ping($1, $2) #done
        when /^PONG +:(.+)$/i , /^PONG +(.+)$/i
            client.handle_pong($1)
        when /^PRIVMSG +([^ ]+) +:(.*)$/i
            client.handle_privmsg($1, $2) #done
        when /^NOTICE +([^ ]+) +(.*)$/i
            client.handle_notice($1, $2) #done
        when /^PART :+([^ ]+) *(.*)$/i  
            #some clients require this.
            client.handle_part($1, $2) #done
        when /^PART +([^ ]+) *(.*)$/i
            client.handle_part($1, $2) #done
        when /^QUIT :(.*)$/i
            client.handle_quit($1) #done
        when /^QUIT *(.*)$/i
            client.handle_quit($1) #done
        when /^TOPIC +([^ ]+) *:*(.*)$/i
            client.handle_topic($1, $2) #done
        when /^AWAY +:(.*)$/i
            client.handle_away($1)
        when /^AWAY +(.*)$/i #for opera
            client.handle_away($1)
        when /^:*([^ ])* *AWAY *$/i
            client.handle_away(nil)
        when /^LIST *(.*)$/i
            client.handle_list($1)
        when /^WHOIS +([^ ]+) +(.+)$/i
            client.handle_whois($1,$2)
        when /^WHOIS +([^ ]+)$/i
            client.handle_whois(nil,$1)
        when /^WHO +([^ ]+) *(.*)$/i
            client.handle_who($1, $2)
        when /^NAMES +([^ ]+) *(.*)$/i
            client.handle_names($1, $2)
        when /^MODE +([^ ]+) *(.*)$/i
            client.handle_mode($1, $2)
        when /^USERHOST +:(.+)$/i
            #besirc does this (not accourding to RFC 2812)
            client.handle_userhost($1)
        when /^USERHOST +(.+)$/i
            client.handle_userhost($1)
        when /^RELOAD +(.+)$/i
            client.handle_reload($1)
        when /^VERSION *$/i
            client.handle_version()
        when /^EVAL (.*)$/i
            #strictly for debug
            client.handle_eval($1)
        else
            client.handle_unknown(s)
        end
        carp "Handled"
    end
    
    def self.ping_all
      $user_store.each_user { |client|
          client.send_ping
      }
    end
    
end