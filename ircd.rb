#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'thread'

DIR = File.dirname(__FILE__)
%w(irc_replies net_utils message_server synchronized_store default_stores irc_channel irc_client irc_server).each do |f|
  require File.join(f)
end

include IRCReplies

$config ||= {}
$config['version'] = '0.1'
$config['timeout'] = 10
$config['port'] = 6667
$config['hostname'] = Socket.gethostname.split(/\./).shift
$config['starttime'] = Time.now.to_s
$config['nick-tries'] = 5

$verbose = ARGV.shift || false
    
CHANNEL = /^[#\$&]+/
PREFIX  = /^:[^ ]+ +(.+)$/

if __FILE__ == $0
    begin
        $verbose ||= !ARGV.detect { |c| c =~ /-v/ }.nil?
        trap("INT") do 
            $message_server.dump
            system("kill -9 #{$$}")
        end
        
        MessageServer.start
        
        EventMachine::run do
          EventMachine::add_periodic_timer(300) { IRCServer.ping_all }
          EventMachine::start_server "0.0.0.0", 6667, IRCServer
        end
    rescue Exception => e
        class P; include NetUtils; end
        P.new.carp e
    end
end
