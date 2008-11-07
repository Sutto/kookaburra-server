require 'drb'

# Ugly ass DRB message server class.
# Needs to be seriously refactored.
class MessageServer
  
  def self.stored_messages_path; File.join(Kookaburra.root, "data/messages"); end
  
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
    return formatted(m).reverse[0..(limit - 1)]
  end
  
  def messages_for(chan)
    m = []
    @mutex.synchronize do
      m = @messages[chan.downcase] || []
    end
    formatted m
  end
  
  def replies_to(username)
    m = []
    @mutex.synchronize do
      m = @messages.values.flatten.select { |m| m.target[0] == ?#  && m.content =~ /(@#{username}|#{username}:)/i  }
    end
    formatted m
  end
  
  def append_message(from, to, contents, viewed = true)
    @mutex.synchronize do
      messages = (@messages[to.downcase] ||= [])
      messages.shift if messages.length >= MESSAGE_LIMIT
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
    user_from = Kookaburra::Stores.users[from]
    # from is not online, so choose the correct item to do.
    if user_from.nil?
      target    = (to =~ /^[#\$&]+/ ? Kookaburra::Stores.channels[to] : Kookaburra::Stores.users[to])
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
      Kookaburra.logger.info "Sending privmsg #{to} from #{from} w/ '#{text}'"
      user_from.reply :privmsg, user_from.userprefix, to, text
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
    return filter_public(m).sort_by { |m| m.created_at }.map { |m| m.values }
  end
  
  def filter_public(m = [])
    m.select { |m| m.target =~ /^[#\$&]+/ }
  end
  
  def start
    DRb.start_service('druby://localhost:9000', self)
  end
  
  def self.start
    c = self.new
    c.load
    c.start
    return c
  end
  
  def dump
    Kookaburra.logger.info "Writing out messages to file"
    File.open(MessageServer.stored_messages_path, "w+") do |f|
      f.write Marshal.dump(@messages)
    end
  end
  
  def load
    if File.exist?(MessageServer.stored_messages_path)
      Kookaburra.logger.info "Loading stored messages"
      c = File.read(MessageServer.stored_messages_path)
      @messages = Marshal.load(c)
      @@base_id = @messages.values.flatten.map { |m| m.message_id }.max || 0
    end
  rescue Exception => e
    Kookaburra.logger.error "Couldn't reload stored messages"
    Kookaburra.logger.debug_exception e
    @messages = {}
  end
  
end