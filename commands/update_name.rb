require "cgi"

update_name = proc do |json, *match|
  str = CGI.unescapeHTML(json[:text].sub(match[1], ""))
  begin
    twitter.update_profile(name: str)
    twitter.update(str.gsub(/[@＠]/, ""))
  rescue
    twitter.update("@#{json[:user][:screen_name]} 表示名を更新できませんでした(∩´﹏`∩)",
                   in_reply_to_status_id: json[:id])
  end
end

on_tweet(/^[@＠]#{user.screen_name}\s+update_name\s*(.+)$/, &update_name)
on_tweet(/([(（][@＠]#{user.screen_name}[)）])/, &update_name)

