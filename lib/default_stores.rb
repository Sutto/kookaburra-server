$user_store = SynchronizedStore.new
class << $user_store
    def <<(client)
        self[client.nick] = client
    end
    
    alias nicks keys
    alias each_user each_value 
end

$channel_store = SynchronizedStore.new
class << $channel_store
    def add(c)
        self[c] ||= IRCChannel.new(c)
    end

    def remove(c)
        self.delete[c]
    end
    
    alias each_channel each_value 
    alias channels keys
end