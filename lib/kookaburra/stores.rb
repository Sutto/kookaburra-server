module Kookaburra
  class Stores
    @@user_store    = TSStore.named(:nicks, :user)
    @@channel_store = TSStore.named(:channels, :channel)
    
    class << self
      def users
        @@user_store
      end
      
      def channels
        @@channel_store
      end
    end
  end
end