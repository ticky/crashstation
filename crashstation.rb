#!/usr/bin/env ruby

# CrashStation! (Ruby portion) by Jessica Stokes
#
# Launches a PocketStation game in MAME, capturing 30 seconds of output as a gif
#
# Direct usage:
# `ruby crashstation.rb`

require 'rmagick'
require 'date'

def run_emulator
  puts 'Running emulator...'

  utc_offset = 36000

  %x[
    TZ=LOL#{(-utc_offset / 3600).round.to_s} \
      mame \
        -sound none \
        -seconds_to_run 60 \
        pockstat \
        -autoboot_script #{__dir__}/crashstation.lua \
        -cart #{__dir__}/crash.gme
  ]
end

LINES_PER_FRAME = 35

def process_video_data(video_data)
  raw_lines = video_data.lines

  puts "Processing #{raw_lines.length} lines (#{raw_lines.length / LINES_PER_FRAME} frames) of video data..."

  generated_gif = Magick::ImageList.new

  until raw_lines.empty? do
    frame_data = raw_lines.shift LINES_PER_FRAME

    delay = frame_data.shift.to_f

    frame_data.shift # remove the separator line
    frame_data.pop # remove the other separator line

    frame_pixels = []

    frame_data.map do |scanline|
      frame_pixels.concat(
        scanline
          .to_i
          .to_s(2)
          .rjust(32, '0')
          .split('')
          .reverse
          .map! do |pixel|
            Magick::Pixel.from_color(pixel == '1' ? 'black' : 'white')
          end
      )
    end

    # frame delays are off by one, oops
    generated_gif.new_image(32, 32)
    generated_gif.last.tap do |new_frame|
      new_frame.store_pixels(0, 0, 32, 32, frame_pixels)
      new_frame.delay = delay * new_frame.ticks_per_second
      new_frame.resize! 192, 192, Magick::PointFilter
    end
  end

  generated_gif.write "crashstation-#{DateTime.now.strftime '%FT%H%M%S'}.gif"

  puts 'Done!'
end

process_video_data(run_emulator)
