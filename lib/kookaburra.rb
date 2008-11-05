$:.unshift(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'

# Require our external files.
require File.join(File.dirname(__FILE__), '../vendor/trollop')

# Check the gems exist
gem 'configatron',  '>= 2.0.0'
gem 'extlib',       '>= 0.9.8'
gem 'eventmachine', '>= 0.12.0'

# And require them
require 'configatron'
require 'extlib'
require 'eventmachine'
require 'message_server'

module Kookaburra
  
  VERSION = "0.1"
  
  Settings = Configatron.instance
  
  autoload :Options,  'kookaburra/options'
  autoload :Logger,   'kookaburra/logger'
  autoload :Control,  'kookaburra/control'
  autoload :IRC,      'kookaburra/irc'
  autoload :TSStore,  'kookaburra/ts_store'
  autoload :Stores,   'kookaburra/stores'
  
  # Include the extra stuff
  require 'kookaburra/base_extension'
  extend Kookaburra::BaseExtension
  
end