require 'twitter_ebooks'
require 'tempfile'
require './crashstation'

LYRICS = [
  'Crash Bandicoot, Crash Bandicoot~',
  'Crash Bandi-bandicoot!',
  'He jumps to do a spin attack',
  'In an abandoned place, yes yes yes',
  'Out and collecting apples for dinner',
  'Heʼs not scared even if itʼs shaking, rumbling',
  'Crash has been everywhere!'
].freeze

class CrashStationBot < Ebooks::Bot
  def configure
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = '' # Your app consumer key
    self.consumer_secret = '' # Your app consumer secret

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 0..600
  end

  def make_public_tweet
    gif = CrashStation.make_gif
    file = Tempfile.new('image')
    gif.write("gif:#{file.path}")
    tweet(LYRICS.sample, media_ids: twitter.upload(file).to_s)
  end

  def on_message(dm)
    tweet = make_public_tweet
    reply(dm, "#{LYRICS.sample} It's up at #{tweet.uri}")
  end

  def on_startup
    scheduler.every '2m' do
      delay do
        make_public_tweet
      end
    end
  end
end

CrashStationBot.new('crashstation') do |bot|
  bot.access_token = '' # Token connecting the app to this account
  bot.access_token_secret = '' # Secret connecting the app to this account
end
