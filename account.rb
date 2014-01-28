require "em-twitter"
require "twitter"
require "json"
require "./command"

class Account
  attr_reader :twitter, :logger

  def initialize(token, logger)
    @twitter = Twitter::REST::Client.new(token)
    @stream = EM::Twitter::Client.new(host: "userstream.twitter.com",
                                      path: "/1.1/user.json",
                                      oauth: @twitter.credentials,
                                      method: :get)

    @stream.each do |str|
      json = JSON.parse(str, symbolize_names: true) rescue next

      if json[:text] && !json[:retweeted_status]
        serve(:tweet, json)
      elsif json[:event]
        serve(json[:event].to_sym, json)
      elsif json[:friends]
        serve(:friends, json)
      end
    end

    @callbacks = {}
    @logger = logger
    @logger.progname = user.screen_name
  end

  def add_command(filename)
    @commands ||= []
    @commands << Command.new(self, filename)
  end

  def start
    @stream.connect
  end

  def register_callback(event, blk)
    @callbacks[event] ||= []
    @callbacks[event] << blk
  end

  def user(update: false)
    if !@_user || update
      @_user = twitter.user
    end

    @_user
  end

  def serve(event, json)
    @callbacks[event] && @callbacks[event].each do |c|
      EM.defer do
        begin
          c.call(json)
        rescue
          logger.error("Failed to execute callback: #{event}: #{$!}\n#{$@}")
        end
      end
    end
  end
end

