require "cgi"

update_name = ->(str, json) do
  begin
    twitter.update_profile(name: str)
    twitter.update("@#{json[:user][:screen_name]} #{str.gsub(/[@＠]/, "(at)")} になりました",
                   in_reply_to_status_id: json[:id])
  rescue
    twitter.update("@#{json[:user][:screen_name]} 表示名を更新できませんでした(∩´﹏`∩)",
                   in_reply_to_status_id: json[:id])
  end
end

on_tweet(/^[@＠]#{user.screen_name}\s+update_name\s*(.+)$/) do |json, *match|
  str = CGI.unescapeHTML(match[1])
  update_name.call(str, json)
end

on_tweet(/([(（][@＠]#{user.screen_name}[)）])/) do |json, *match|
  str = CGI.unescapeHTML(json[:text].sub(match[1], ""))
  update_name.call(str, json)
end

