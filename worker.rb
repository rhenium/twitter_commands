require "em-twitter"
require "twitter"
require "json"
require "./tokens"

def twitter
  @_twitter ||= Twitter::REST::Client.new(consumer_key: CONSUMER_KEY, consumer_secret: CONSUMER_SECRET, oauth_token: OAUTH_TOKEN, oauth_token_secret: OAUTH_TOKEN_SECRET)
end

def user(update: false)
  if !@_user || update
    @_user = twitter.user
  end

  @_user
end

def serve(event, json)
  @events ||= {}
  @events[event] && @events[event].each do |c|
    EM.defer do
      begin
        c.call(json)
      rescue
        puts "Failed to execute callback: #{event}: #{$!}"
        puts $@
      end
    end
  end
end

def on_event(event, &blk)
  @events ||= {}
  @events[event] ||= []
  @events[event] << blk
end

def on_tweet(regexp, &blk)
  on_event(:tweet) do |json|
    match = regexp.match(json[:text])
    if match
      blk.call(json, *match)
    end
  end
end

def mainloop
  EM.run do
    client = EM::Twitter::Client.new(
      host: "userstream.twitter.com",
      path: "/1.1/user.json",
      oauth: twitter.credentials,
      method: :get
    )

    client.each do |str|
      json = JSON.parse(str, symbolize_names: true) rescue next

      if json[:text] && !json[:retweeted_status]
        serve(:tweet, json)
      elsif json[:event]
        serve(json[:event].to_sym, json)
      end
    end

    client.connect
  end
end

def load_commands
  Dir.glob(File.expand_path("../commands/*.rb", __FILE__)) do |file|
    begin
      load file
    rescue
      puts "Failed to load command: #{File.basename(file)}: #{$!}"
      puts $@
    end
  end
end

load_commands
mainloop

