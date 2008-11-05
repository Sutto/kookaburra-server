module Kookaburra
  module IRC
    class CatchAll

      def privatemsg(msg, client)
        # Broadcast to all users
        Kookaburra::Stores.users.each_user do |user|
          user.reply :privmsg, client.userprefix, "#all", msg
        end
      end

      def notice(msg, client)
          Kookaburra::Stores.users.each_user do |user|
              user.reply :notice, client.userprefix, @name, msg
          end
      end

      def each_user(&blk)
        Kookaburra::Stores.users.each_user(&blk)
      end

      def name; "#all"; end

      def nicks; Kookaburra::Stores.users.nicks; end

      def topic
        "All that is posted on Kookaburra"
      end

      def join(client);      true; end

      def part(client, msg); true; end

      def quit(client, msg); true; end

      def is_member?(user);  true; end
      alias has_nick? is_member?

      def mode(u)
        " "
      end

    end 
  end
end