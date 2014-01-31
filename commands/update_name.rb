require "cgi"

def update_name(str, json)
  user = twitter.update_profile(name: str)
  twitter.update("@#{json[:user][:screen_name]} #{user.name.gsub(/[@＠]/, "(at)")}になりました",
                 in_reply_to_status_id: json[:id])
  logger.info "Successfully updated name to \"#{user.name}\" (triggered by #{json[:user][:screen_name]})"
rescue
  twitter.update("@#{json[:user][:screen_name]} 表示名を更新できませんでした(∩´﹏`∩)",
                 in_reply_to_status_id: json[:id])
  logger.info "Failed to update name to \"#{str}\" (triggered by #{json[:user][:screen_name]})"
end

on_tweet(/^[@＠]#{screen_name}\s+update_name\s*(.+)$/) do |json, match|
  str = CGI.unescapeHTML(match[1])
  update_name(str, json)
end

on_tweet(/([(（]\s*[@＠]#{screen_name}\s*[)）])/) do |json, match|
  str = CGI.unescapeHTML(json[:text].sub(match[1], ""))
  update_name(str, json)
end

