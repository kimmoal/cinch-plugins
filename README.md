Plugins for Cinch
=================

Repository for my plugins for the
[Cinch](https://github.com/cinchrb/cinch) IRC bot

- Bing translate
- Streaming twitter client with reply functionality similar to `bitlbee`

Usage
-----

Example bot configuration for Twitter stream functionality

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ruby
require "cinch"
require "plugins/twitter_client"

Conf = YAML.load_file("config.yml")

cinch = Cinch::Bot.new do
  configure do |config|
    config.server = "irc.freenode.net"
    config.channels = ["#bots"]
    config.nick = "twitter-cinch"
    config.plugins.plugins = [Cinch::TweetStream]

  end

  trap "SIGINT" do
    bot.quit
  end
end

cinch.start
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
