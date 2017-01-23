require 'twitter'

module Cinch::Plugins
  class TwitterClient
    include Cinch::Plugin


    def initialize(*args)
      super
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key        = Conf[:twitter][:consumer_key]
        config.consumer_secret     = Conf[:twitter][:consumer_secret]
        config.access_token        = Conf[:twitter][:access_token]
        config.access_token_secret = Conf[:twitter][:access_token_secret]
      end
      @tweets = Array.new(100)
    end

    match /(.+) (.+)/, method: :tweet_to, prefix: /^@/, react_on: :message
    match /reply (\d+) (.+)/, method: :reply_to, prefix: /^!/, react_on: :message
    match /tweet (.+)/, method: :tweet, prefix: /^!/, react_on: :message

    listen_to :twitter_tweets, method: :save_tweet

    def save_tweet(m, id, tweet)
       @tweets[id] = tweet
    end

    def tweet_to(m, recipient, message)
      @client.update("@#{recipient} #{message}")
      m.reply "@#{recipient} #{message}"
    end

    def reply_to(m, id, message)
      id = id.to_i
      @client.update("@#{@tweets[id].user.screen_name} #{message}", in_reply_to_status: @tweets[id])
      m.reply "Replied to #{@tweets[id].user.screen_name}: #{'%.20s' % @tweets[id].full_text}..."
    end
      
    def tweet(m, message)
      @client.update(message)
    end

  end
end
