require "logger"
require "./account"
require "./command"
require "./tokens"

commands = Dir.glob(File.expand_path("../commands/*.rb", __FILE__))

EM.run do
  TOKENS.each do |token|
    account = Account.new(token, Logger.new(STDOUT))

    commands.each do |filename|
      begin
        account.add_command(filename)
      rescue
        puts "Failed to load command: #{File.basename(filename)}: #{$!}"
        puts $@
      end
    end

    account.start
  end
end

