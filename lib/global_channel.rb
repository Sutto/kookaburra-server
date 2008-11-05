class GlobalChannel
  
  def privatemsg(msg, client)
    # Broadcast to all users
    $user_store.each_user do |user|
      user.reply :privmsg, client.userprefix, "#all", msg
    end
  end
  
  def notice(msg, client)
      $user_store.each_user {|user|
          user.reply :notice, client.userprefix, @name, msg
      }
  end
  
  def each_user(&blk)
    $user_store.each_user(&blk)
  end
  
  def name; "#all"; end
  
  def nicks; $user_store.nicks + ["Steve"]; end
  
  def topic
    "All that is posted on Kookaburra"
  end
  
  def join(client); true; end
  
  def part(client, msg); true; end
  
  def quit(client, msg); true; end
  
  def is_member?(user); true; end
  alias has_nick? is_member?
  
  def mode(u)
    u == "Steve" ? "@" : " "
  end
  
end