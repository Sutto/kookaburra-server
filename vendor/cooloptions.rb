# Copyright:: Copyright (c) 2006 Nathaniel Talbott and Terralien, Inc. All Rights Reserved.
# License:: The RUBY license.
 
require 'optparse'
require 'ostruct'
 
# For a high-level overview of using CoolOptions, see README.txt.
#
# == Usage
#
#   :include:samples/literate.rb
 
class CoolOptions
  VERSION = '1.1.0' #:nodoc:
 
  class Error < StandardError #:nodoc:
  end
 
  # Takes an optional banner and the arguments you want to parse (defaults to
  # ARGV) and yields a new CoolOptions to the supplied block. You can then
  # declare your options in the block using the #on method, and do post-
  # processing using #after. When processing is done, an OpenStruct
  # containing the parsed options is returned.
  def self.parse!(banner="[options]", argv=ARGV) #:yields: cooloptions
    o = new(banner)
    yield o
    o.parse!(argv)
  rescue Error => e
    out.puts e.message
    o.help true
  end
  
  def self.out #:nodoc:
    @out || STDOUT
  end
  
  def out #:nodoc:
    self.class.out
  end
  
  def self.out=(out) #:nodoc:
    @out = out
  end
  
  attr_reader :parser, :result
  
  def initialize(banner) #:nodoc:
    @parser = OptionParser.new
    @parser.banner = "Usage: #{File.basename($0)} #{banner}"
 
    @required = []
    @result = {}
    @after = nil
    @used_shorts = {}
  end
  
  # Adds additional descriptive text to the help text.
  def desc(string)
    string.each_line do |s|
      @parser.separator s.chomp
    end
  end
  
  NO_DEFAULT = Object.new #:nodoc:
  
  # Called on cooloptions within the #parse! block to add options to parse on.
  # Long is the long option itself, description is, well, the description, and
  # default is the default value for the option, if any.
  def on(long, description, default=NO_DEFAULT)
    if /^(.)\)(.+)$/ =~ long
      short, long = $1, $2
    elsif /^(.*)\((.)\)(.*)$/ =~ long
      short = $2
      long = $1 + $2 + $3
    end
    short = long[0,1] unless short
 
    key = long.split(/ /).first.gsub('-', '_').to_sym
 
    unless long =~ / /
      long = "[no-]#{long}"
    end
 
    args = []
    args << "-#{short}" unless @used_shorts[short]
    @used_shorts[short] = true
    args.concat(["--#{long}", description])
    if default == NO_DEFAULT
      @required << key
    else
      @result[key] = default
      args << "Default is: #{default}"
    end
 
    @parser.on(*args){|e| self.result[key] = e}
  end
  
  def parse!(argv) #:nodoc:
    @parser.on('-h', '--help', "This help info."){help}
    @parser.parse!(argv)
 
    @required.reject!{|e| @result.key?(e)}
    error "Missing required options: #{@required.join(', ')}" unless @required.empty?
 
    r = OpenStruct.new(@result)
    @after.call(r) if @after
    r
  end
  
  # If you want to throw an option parsing error, just call #error with a
  # message and CoolOptions will bail out and display the help message.
  def error(message)
    raise Error, message, caller
  end
  
  # CoolOptions only handles options parsing, and it only does rudimentary
  # option validation. If you want to do more, #after is a convenient place do
  # it, especially since the right thing will just happen if you call #error.
  def after(&after)
    @after = after
  end
  
  def help(error=false) #:nodoc:
    out.puts @parser
    exit(error ? 1 : 0)
  end
end