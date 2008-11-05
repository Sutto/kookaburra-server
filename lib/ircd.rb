#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'thread'

DIR = File.dirname(__FILE__)
%w(message_server synchronized_store default_stores
   irc_channel irc_client irc_server global_channel irc_logger kookaburra).each do |f|
  require File.join(DIR, f)
end

$channel_store["#all"] = GlobalChannel.new

CHANNEL = /^[#\$&]+/
PREFIX  = /^:[^ ]+ +(.+)$/