module Kookaburra
  class Stores
    @@user_store    = TSStore.named(:nicks, :user)
    @@channel_store = TSStore.named(:channels, :channel)
    @@ping_store    = TSStore.named(:nicks, :ping_count)
    @@ping_store.default = 0
    
    class << self
      def users
        @@user_store
      end
      
      def channels
        @@channel_store
      end
      
      def pings
        @@ping_store
      end
    end
  end
end