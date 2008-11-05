module Kookaburra
  # Simple thread-safe store.
  class TSStore

      def initialize
        @store = {}
        @mutex = Mutex.new
      end

      def method_missing(name,*args, &blk)
        @mutex.synchronize {  @store.__send__(name,*args, &blk) }
      end

      def each_value(&blk)
        @mutex.synchronize do
          @store.each_value do |u|
            @mutex.unlock
            yield u
            @mutex.lock
          end
        end
      end

      def keys
        @mutex.synchronize { @store.keys }
      end

      def self.named(keys_name, value_name)
        klass = Class.new(self)
        klass.class_eval do
          alias_method keys_name.to_sym, :keys
          alias_method :"each_#{value_name}", :each_value
        end
        return klass.new
      end

  end
end