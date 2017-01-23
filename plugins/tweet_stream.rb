require 'twitter'
require 'htmlentities'

class TweetStream
  EVENT_KEY = :twitter_user_stream
  TWEETS = :twitter_tweets

  attr_reader :bot, :client

  def initialize(bot)
    @bot = bot
    @client = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = Conf[:twitter][:consumer_key]
      config.consumer_secret     = Conf[:twitter][:consumer_secret]
      config.access_token        = Conf[:twitter][:access_token]
      config.access_token_secret = Conf[:twitter][:access_token_secret]
    end
    @tweets = Array.new(100)
    @reply_id = 0
  end

  def run

    # A list of integer user ids
    follow = Conf[:tweetstream][:follow].join(',')

    bot.loggers.info "Starting filter"
    client.filter(follow: follow) do |object|
    case object
      when Twitter::Streaming::DeletedTweet
         then handle_deleted(object)
      when Twitter::Streaming::StallWarning
         then bot.loggers.error "Stalling!"
      when Twitter::Tweet
         then handle_tweet(object) 
      else
         handle_object(object)
    end
    end
  rescue => e
    bot.loggers.error "Stream failed. #{e.inspect} — retry in 120secs."
    sleep 120
    retry
  end

  private
  def handle_tweet(tweet)
    # No retweets or replies
    if tweet.retweet?
      bot.loggers.info "Retweet: #{tweet.user.screen_name}: #{tweet.full_text}"
    elsif !tweet.reply?
      format_tweet(tweet)
    elsif tweet.in_reply_to_user_id == Conf[:tweetstream][:bot_id][0]
      format_tweet(tweet)
    else
      bot.loggers.info "Reply: #{tweet.user.screen_name}: #{tweet.full_text}"
    end
  end

  def format_tweet(tweet)
    text = HTMLEntities.new.decode(tweet.full_text)
    bot.loggers.info "Tweet: #{tweet.inspect}"
    send_to_channel "[#{@reply_id}] #{tweet.user.screen_name}: #{text}"
    save_tweet(tweet)
  end

  def handle_deleted(tweet)
    bot.loggers.info "Tweet: #{tweet.inspect}"
    send_to_channel "Removed: #{tweet.user_id} #{tweet.id}"
  end

  def handle_object(object)
    bot.loggers.info "Unknown Tweet Object: #{object.inspect}"
  end

  def send_to_channel(text)
    bot.handlers.dispatch(EVENT_KEY, nil, text)
  end

  def save_tweet(tweet)
    bot.handlers.dispatch(TWEETS, nil, @reply_id, tweet)

    @reply_id += 1
    if @reply_id > 99
       @reply_id = 0
    end
  end

end

module Cinch::Plugins
  class TweetStream
    include Cinch::Plugin

    def initialize(*args)
      super
    end

    listen_to ::TweetStream::EVENT_KEY
    def listen(m, text)
      Channel(Conf[:tweetstream][:channel]).send text
    end

  end
end
