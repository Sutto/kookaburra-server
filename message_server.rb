require 'drb'

class MessageServer
  include NetUtils
  
  @@base_id = 0
  
  def self.next_id; @@base_id += 1; end
  
  
  Message = Struct.new(:message_id, :from, :target, :content, :created_at, :viewed)
  
  # Limit to 1000 messages per a queue.
  MESSAGE_LIMIT = 1000
  
  def base_id
    @@base_id
  end
  
  def initialize
    @mutex    = Mutex.new
    @messages = {}
  end
  
  def all_messages(limit = 100)
    m = []
    @mutex.synchronize do
      m = @messages.values.flatten
    end
    return formatted(m)[0..(limit - 1)]
  end
  
  def messages_for(chan)
    m = []
    @mutex.synchronize do
      m = @messages[chan.downcase] || []
    end
    formatted m
  end
  
  def append_message(from, to, contents, viewed = true)
    @mutex.synchronize do
      messages = (@messages[to.downcase] ||= [])
      messages.shift if messages.length == 250
      messages << ::MessageServer::Message.new(MessageServer.next_id, from, to, contents, Time.now, viewed)
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
    return [@@base_id, from, to, text, Time.now, true]
  end
  
  def mark_as_viewed!(user)
    @mutex.synchronize do
      (@messages[user.downcase] ||= []).each { |m| m.viewed = true}
    end
  end
  
  def unviewed_for(user)
    return @mutex.synchronize { (@messages[user.downcase] ||= []).select { |m| m.viewed = true} }
  end
  
  def formatted(m = [])
    return filter_public(m).sort_by { |m| m.created_at }.map { |message| [message.message_id, message.from, message.target, message.content, message.created_at, message.viewed ] }
  end
  
  def filter_public(m = [])
    m.select { |m| m.target =~ /^[#\$&]+/ }
  end
  
  def start
    $message_server = self
    DRb.start_service('druby://localhost:9000', $message_server)
  end
  
  def self.start
    c = self.new
    c.load
    c.start
  end
  
  def dump
    carp  "Dumping Data"
    File.open("messages.data", "w+") do |f|
      f.write Marshal.dump(@messages)
    end
  end
  
  def load
    if File.exist?("messages.data")
      carp "Loading data"
      c = File.read("messages.data")
      @messages = Marshal.load(c)
      carp "Messages: #{@messages.class} => #{@messages.size}"
      @@base_id = @messages.values.flatten.map { |m| m.message_id }.max || 0
      carp "Data loaded!"
      carp "Base id: #{@@base_id}"
    end
  rescue Exception => e
    carp "Error loading data"
    carp e
    @messages = {}
  end
  
end