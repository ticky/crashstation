#!/usr/bin/env ruby

# CrashStation! (Ruby portion) by Jessica Stokes
#
# Launches a PocketStation game in MAME, capturing 30 seconds of output as a gif
#
# Direct usage:
# `./crashstation.rb`

require 'rmagick'
require 'date'

LINES_PER_FRAME = 35

def process_video_data(video_data)
  raw_lines = video_data.lines

  num_frames = raw_lines.length / LINES_PER_FRAME

  puts "Processing ~#{num_frames} frames of video data..."
  puts "(#{raw_lines.length} lines supplied)"

  generated_gif = Magick::ImageList.new do
    self.background_color = 'transparent'
  end

  until raw_lines.length < LINES_PER_FRAME
    frame_data = raw_lines.shift LINES_PER_FRAME

    frame_data.pop # remove the other separator line
    delay = frame_data.pop.to_f
    frame_data.pop # remove the separator line

    frame_pixels = process_frame_pixels(frame_data)

    generated_gif.new_image(32, 32)
    generated_gif.last.tap do |new_frame|
      new_frame.store_pixels(0, 0, 32, 32, frame_pixels)
      new_frame.delay = delay * new_frame.ticks_per_second
      new_frame.resize! 192, 192, Magick::PointFilter
    end
  end

  filename = "crashstation-#{DateTime.now.strftime '%FT%H%M%S'}.gif"

  generated_gif.write filename

  puts "Wrote GIF to \"#{filename}\"."
  puts 'Done!'
end

def process_frame_pixels(frame_data)
  frame_pixels = []

  frame_data.each do |scanline|
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

  frame_pixels
end

def run_emulator(utc_offset = 36_000)
  puts 'Running emulator...'

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

process_video_data(run_emulator(rand(-24..24) * 3600))
