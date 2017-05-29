require 'twitter_ebooks'
require 'tempfile'
require './crashstation'

# lyrics are from https://youtu.be/6CzX2JUqDuI
LYRICS = [
  'Crash Bandicoot, Crash Bandicoot~',
  'Crash Bandi-bandicoot!',
  'He jumps to do a spin attack',
  'In an abandoned place, yes yes yes',
  'Out and collecting apples for dinner',
  'Heʼs not scared even if itʼs shaking, rumbling',
  'Crash has been everywhere!',
  'Dashing around in his jeans, always feels good, bye bye bye!',
  'Wouldnʼt everybody like to go on a vacation?',
  'This place looks nice, right?',
  'Yeah, heʼs sneaking around everywhere',
  'Is it okay to be doing that here?',
  'Uuh everybody break out before a terrible surprise makes you jump'
].freeze

class CrashStationBot < Ebooks::Bot
  def configure
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = '' # Your app consumer key
    self.consumer_secret = '' # Your app consumer secret

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 0..180
  end

  def make_gif(**args)
    gif = CrashStation.make_gif(**args)
    file = Tempfile.new('image')
    gif.write("gif:#{file.path}")
    file
  end

  def make_public_tweet(**args)
    tweet(
      LYRICS.sample,
      media_ids: twitter.upload(make_gif(**args)).to_s
    )
  end

  def on_mention(tweet)
    puts "DEBUG: Sender UTC Offset: #{tweet.user.utc_offset}"

    gif = make_gif(utc_offset: tweet.user.utc_offset)

    delay do
      reply(
        tweet,
        LYRICS.sample,
        media_ids: twitter.upload(gif).to_s
      )
    end
  end

  def on_message(dm)
    puts "DEBUG: Sender UTC Offset: #{dm.sender.utc_offset}"
    tweet = make_public_tweet(utc_offset: dm.sender.utc_offset)
    reply(dm, "#{LYRICS.sample} It's up at #{tweet.uri}")
  end

  def on_startup
    scheduler.every '28m' do
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
