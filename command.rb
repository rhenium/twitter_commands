class Command
  def initialize(account, filename)
    @_account = account

    self.instance_eval(File.read(filename))
  end

  def twitter
    @_account.twitter
  end

  def logger
    @_account.logger
  end

  def screen_name
    @_account.user.screen_name
  end

  def user_id
    @_account.user.id
  end

  def on_event(event, &blk)
    @_account.register_callback(event, blk)
  end

  def on_tweet(regexp, &blk)
    on_event(:tweet) do |json|
      if match = regexp.match(json[:text])
        blk.call(json, match)
      end
    end
  end
end

