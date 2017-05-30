#!/usr/bin/env ruby

# CrashStation! (Ruby portion) by Jessica Stokes
#
# Launches a PocketStation game in MAME, capturing 30 seconds of output as a gif
#
# Direct usage:
# `./crashstation.rb`

require 'rmagick'
require 'date'

module CrashStation
  extend self

  #if argv[0] is test, run using the test data
  #otherwise run using mame data
  def make_gif_wrapper()
    if (ARGV[0] == 'test') then
      make_gif_cli_test()
    else
      make_gif_cli()
    end
  end

  def make_gif_cli(
    game_filename: "#{__dir__}/crash.gme",
    gif_filename: make_filename,
    **args
  )
    puts 'Running mame...'
    video_data = run_emulator(game_filename, **args)

    puts 'Processing video data...'
    gif = process_video_data(video_data)

    puts 'Writing gif...'
    gif.write gif_filename

    puts "Wrote GIF to \"#{gif_filename}\"."
    puts 'Done!'
  end

  def make_gif_cli_test(
    test_filename: "#{__dir__}/fixtures/test-video-data.txt",
    gif_filename: make_filename,
    **args
  )
    puts 'Loading test video data...'
    video_data = File.read test_filename
    
    puts 'Processing video data...'
    gif = process_video_data(video_data)

    puts 'Writing gif...'
    gif.write gif_filename

    puts "Wrote GIF to \"#{gif_filename}\"."
    puts 'Done!'
  end

  def make_gif(
    game_filename: "#{__dir__}/crash.gme",
    **args
  )
    process_video_data(run_emulator(game_filename, **args))
  end

  SCREEN_SIZE = 32
  LINES_PER_FRAME = SCREEN_SIZE + 3

  def process_video_data(video_data)
    raw_lines = video_data.lines

    Magick::ImageList.new.tap do |gif|
      add_first_frame_to gif, raw_lines.shift(LINES_PER_FRAME)
      until raw_lines.length < LINES_PER_FRAME
        add_frame_to gif, raw_lines.shift(LINES_PER_FRAME)
      end
    end
  end

  def add_first_frame_to(gif, frame) #Edit the delay for the first frame
    frame.pop # remove the separator line
    frame.pop # ignore the first frame delay
    frame.pop # remove the other separator line

    delay = 0.5 # Half-second delay for the first frame

    gif.new_image(SCREEN_SIZE, SCREEN_SIZE)
    gif.last.tap do |gif_frame|
      pixels = raw_frame_to_pixels frame
      gif_frame.store_pixels 0, 0, SCREEN_SIZE, SCREEN_SIZE, pixels
      gif_frame.delay = delay * gif_frame.ticks_per_second
      gif_frame.resize! SCREEN_SIZE * 6, SCREEN_SIZE * 6, Magick::PointFilter
    end
  end

  def add_frame_to(gif, frame)
    frame.pop # remove the separator line
    delay = frame.pop.to_f
    frame.pop # remove the other separator line

    gif.new_image(SCREEN_SIZE, SCREEN_SIZE)
    gif.last.tap do |gif_frame|
      pixels = raw_frame_to_pixels frame
      gif_frame.store_pixels 0, 0, SCREEN_SIZE, SCREEN_SIZE, pixels
      gif_frame.delay = delay * gif_frame.ticks_per_second
      gif_frame.resize! SCREEN_SIZE * 6, SCREEN_SIZE * 6, Magick::PointFilter
    end
  end

  def raw_frame_to_pixels(frame)
    [].tap do |frame_pixels|
      frame.each do |scanline|
        frame_pixels.concat process_scanline(scanline)
      end
    end
  end

  def process_scanline(scanline)
    scanline
      .to_i
      .to_s(2)
      .rjust(32, '0')
      .split('')
      .reverse
      .map! do |pixel|
        Magick::Pixel.from_color(pixel == '1' ? 'black' : 'white')
      end
  end

  def run_emulator(game_file, utc_offset: rand(-24..24) * 3600)
    timezone = (-utc_offset / 3600).round.to_s

    %x[
      TZ=LOL#{timezone} \
        mame \
          -video none \
          -sound none \
          -seconds_to_run 60 \
          pockstat \
          -autoboot_script #{__dir__}/crashstation.lua \
          -cart #{game_file}
    ]
  end

  def make_filename
    "crashstation-#{DateTime.now.strftime '%FT%H%M%S'}.gif"
  end
end

CrashStation.make_gif_wrapper if __FILE__ == $PROGRAM_NAME
