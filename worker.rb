require "net/https"
require "oauth"
require "json"
require "cgi"
require "./tokens"

def access_token
  @_access_token ||= begin
    consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, site: "https://api.twitter.com")
    OAuth::AccessToken.new(consumer, OAUTH_TOKEN, OAUTH_TOKEN_SECRET)
  end
end

def screen_name
  @_screen_name ||= begin
    res = access_token.get("/1.1/account/verify_credentials.json")
    JSON.parse(res.body, symbolize_names: true)[:screen_name]
  end
end

def reply(str, status)
  access_token.post("/1.1/statuses/update.json",
                    status: "@#{status[:user][:screen_name]} #{str}",
                    in_reply_to_status_id: status[:id])
end

def update_name(str, status)
  str = CGI.unescapeHTML(str)
  res = access_token.post("/1.1/account/update_profile.json", name: str)
  if res.code.to_i == 200
    reply(str.gsub(/[@＠]/, "(at)"), status)
  else
    reply("表示名を更新できませんでした(∩´﹏`∩)", status)
  end
end

def mainloop
  uri = URI.parse("https://userstream.twitter.com/1.1/user.json")

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  https.start do
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept-Encoding"] = "identity;q=1"
    request.oauth!(https, access_token.consumer, access_token)

    https.request(request) do |res|
      buf = ""
      res.read_body do |chunk|
        buf << chunk
        while line = buf.slice!(/^.+?(\r\n)+/)
          status = JSON.parse(line, symbolize_names: true) rescue next
          next unless status[:text] #&& status[:user][:screen_name] != screen_name

          if /^[@＠]#{screen_name}\s+update_name\s*(.+)$/ =~ status[:text]
            update_name($1, status)
          elsif /([(（][@＠]#{screen_name}[)）])/ =~ status[:text]
            update_name(status[:text].sub($1, ""), status)
          end
        end
      end
    end
  end
end

mainloop

