require 'drb'

class MessageServer
  include NetUtils
  
  Message = Struct.new(:from, :target, :content, :created_at, :viewed)
  
  MESSAGE_LIMIT = 250
  
  def initialize
    @mutex    = Mutex.new
    @messages = {}
  end
  
  def all_messages(limit = 100)
    m = []
    @mutex.synchronize do
      m = @messages.values.select { |m| m.target =~ /^[#\$&]+/ }
    end
    return formatted(m)[0..(limit - 1)]
  end
  
  def messages_for(chan)
    m = []
    @mutex.synchronize do
      m = @messages[chan] || []
    end
    formatted m
  end
  
  def append_message(from, to, contents, viewed = true)
    @mutex.synchronize do
      messages = (@messages[to] ||= [])
      messages.shift if messages.length == 250
      messages << ::MessageServer::Message.new(from, to, contents, Time.now, viewed)
    end
  end
  
  def messages_from(user_name)
    m = []
    @mutex.synchronize do
      m = @messages.values.flatten.select { |m| m.from == user_name }
    end
    formatted m
  end
  
  def remote_message(from, to, text)
    user_from = $user_store[from]
    # from is not online, so choose the correct item to do.
    if user_from.nil?
      target    = (to =~ /^[#\$&]+/ ? $channel_store[to] : $user_store[to])
      carp "Target: #{target.class.name}"
      if !target.nil?
        prefix = ":#{from}!~unknown@cockatoo-server"
        if to =~ /^[#\$&]+/
          target.privatemsg text, Struct.new(:userprefix).new(prefix)
        else
          target.reply :privmsg, prefix, to, text
        end
      end
      append_message from, to, text, !target.nil?
    else
      carp "Sending privmsg (owner) to #{to} from #{from} w/ '#{text}'"
      user_from.reply :privmsg, user_from.instance_variable_get("@usermsg"), to, text
      carp "Sending privmsg (self) to #{to} from #{from} w/ '#{text}'"
      user_from.handle_privmsg to, text
    end
    return true
  end
  
  def mark_as_viewed!(user)
    @mutex.synchronize do
      (@messages[user] ||= []).each { |m| m.viewed = true}
    end
  end
  
  def unviewed_for(user)
    return @mutex.synchronize { (@messages[user] ||= []).select { |m| m.viewed = true} }
  end
  
  def formatted(m = [])
    return m.sort_by { |m| m.created_at }.map { |message| [message.from, message.target, message.content, message.created_at, message.viewed ] }
  end
  
  def start
    $message_server = self
    DRb.start_service('druby://localhost:9000', $message_server)
  end
  
  def self.start
    self.new.start
  end
  
end