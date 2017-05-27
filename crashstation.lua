-- CrashStation! (Lua portion) by Jessica Stokes
--
-- Launches a PocketStation game in MAME, dumps 30 seconds of frames to STDOUT and exits
--
-- Direct usage:
-- `mame -autoboot_script <path to crashstation.lua> pockstat -cart <memory card image in .gme format>`
-- (that said you probably want to launch via crashstation.rb 👀)
--
-- Shoutouts to;
--  * Kyle Barry for this technical breakdown
--    (http://ktyp.com/library/pocketstation/pocketstation.htm)
--  * Nocash for this remarkably comprehensive memory map
--    (http://problemkaputt.de/psx-spx.htm#pocketstation)

VIDEO_OFFSET   = 0xd000100

-- PocketStation default date, so we can set it using the UI 
DEFAULT_YEAR    = 1999
DEFAULT_MONTH   = 01
DEFAULT_DAY     = 01
DEFAULT_HOURS   = 00
DEFAULT_MINUTES = 00

--print("CrashStation! (running in " .. emu.app_name() .. " " .. emu.app_version() .. ")")

-- grab machine hardware
machine        = manager:machine()
cpu            = machine.devices[":maincpu"]
program_memory = cpu.spaces["program"]
screen         = machine.screens[":screen"]
video          = machine:video()
buttons        = machine:ioport().ports[":BUTTONS"]

-- grab the buttons so we can push 'em
BUTTON_ACTION = buttons.fields["Action Button"]
BUTTON_UP     = buttons.fields["Up"]
BUTTON_RIGHT  = buttons.fields["Right"]
BUTTON_DOWN   = buttons.fields["Down"]
BUTTON_LEFT   = buttons.fields["LEFT"]

NOW = os.date("*t")

-- intro can be skipped after the 100th frame
SKIP_INTRO_FRAME = 100
-- date setting can start after the 102nd frame
SET_DATE_FRAME   = 102

-- 10 frames per button press appears to be about the sweet spot to avoid desyncs
FRAMES_PER_BUTTON = 10

-- numbers of button presses needed to adjust the date and time
BUTTONS_FOR_YEAR    = NOW.year  - DEFAULT_YEAR
BUTTONS_FOR_MONTH   = NOW.month - DEFAULT_MONTH
BUTTONS_FOR_DAY     = NOW.day   - DEFAULT_DAY
BUTTONS_FOR_HOURS   = NOW.hour  - DEFAULT_HOURS
BUTTONS_FOR_MINUTES = NOW.min   - DEFAULT_MINUTES

-- numbers of _frames_ needed to adjust the date and time
SET_YEAR_FRAME        = SET_DATE_FRAME + (BUTTONS_FOR_YEAR * FRAMES_PER_BUTTON)
SET_YEAR_DONE_FRAME   = SET_YEAR_FRAME + FRAMES_PER_BUTTON
SET_MONTH_FRAME       = SET_YEAR_DONE_FRAME + (BUTTONS_FOR_MONTH * FRAMES_PER_BUTTON)
SET_MONTH_DONE_FRAME  = SET_MONTH_FRAME + FRAMES_PER_BUTTON
SET_DAY_FRAME         = SET_MONTH_DONE_FRAME + (BUTTONS_FOR_DAY * FRAMES_PER_BUTTON)
SET_DAY_DONE_FRAME    = SET_DAY_FRAME + FRAMES_PER_BUTTON
SET_HOUR_FRAME        = SET_DAY_DONE_FRAME + (BUTTONS_FOR_HOURS * FRAMES_PER_BUTTON)
SET_HOUR_DONE_FRAME   = SET_HOUR_FRAME + FRAMES_PER_BUTTON
SET_MINUTE_FRAME      = SET_HOUR_DONE_FRAME + (BUTTONS_FOR_MINUTES * FRAMES_PER_BUTTON)
SET_MINUTE_DONE_FRAME = SET_MINUTE_FRAME + FRAMES_PER_BUTTON

-- the frame at which the clock will be set
CLOCK_READY_FRAME  = SET_MINUTE_DONE_FRAME + 10 * FRAMES_PER_BUTTON
-- the frame at which the (first) application will be selected
APP_SELECTED_FRAME = CLOCK_READY_FRAME + FRAMES_PER_BUTTON
-- the frame at which we can launch the application
APP_LAUNCH_FRAME   = APP_SELECTED_FRAME + 2 * FRAMES_PER_BUTTON
-- the frame when the application is launched and we can begin recording
APP_LAUNCHED_FRAME = APP_LAUNCH_FRAME + FRAMES_PER_BUTTON

-- last frame data and index
LAST_FRAME        = nil
LAST_FRAME_NUMBER = APP_LAUNCHED_FRAME - 1

-- number of seconds to record
GIF_TIME = 30

-- let's run this at superspeed!!!
--video.throttle_rate = 9999999999

function read_display()
  buffer = ""

  for scan = 0, 31 do
    buffer = buffer .. program_memory:read_u32(VIDEO_OFFSET + (4 * scan)) .. '\n'
  end

  return buffer
end

function on_frame_done()
  emu.pause()
  frame_number = screen:frame_number()
  next_frame_number = frame_number + 1
  refresh_rate = screen:refresh()

  -- reset all buttons after each frame
  for _, button in pairs(buttons.fields) do
    button:set_value(0x0)
  end

  -- SKIP_INTRO_FRAME is the first paint of the "Hello" screen! After this, we can start setting the date and time!
  if next_frame_number == SKIP_INTRO_FRAME or next_frame_number == SET_DATE_FRAME then
    BUTTON_UP:set_value(0xF)
  end

  -- Set the date and time!
  if (next_frame_number % FRAMES_PER_BUTTON) == 0 then
    if next_frame_number > SET_DATE_FRAME and next_frame_number <= SET_YEAR_FRAME then
      BUTTON_UP:set_value(0xF)
    end

    if next_frame_number > SET_YEAR_FRAME and next_frame_number <= SET_YEAR_DONE_FRAME then
      BUTTON_RIGHT:set_value(0xF)
    end

    if next_frame_number > SET_YEAR_DONE_FRAME and next_frame_number <= SET_MONTH_FRAME then
      BUTTON_UP:set_value(0xF)
    end

    if next_frame_number > SET_MONTH_FRAME and next_frame_number <= SET_MONTH_DONE_FRAME then
      BUTTON_RIGHT:set_value(0xF)
    end

    if next_frame_number > SET_MONTH_DONE_FRAME and next_frame_number <= SET_DAY_FRAME then
      BUTTON_UP:set_value(0xF)
    end

    if next_frame_number > SET_DAY_FRAME and next_frame_number <= SET_DAY_DONE_FRAME then
      BUTTON_RIGHT:set_value(0xF)
    end

    if next_frame_number > SET_DAY_DONE_FRAME and next_frame_number <= SET_HOUR_FRAME then
      BUTTON_UP:set_value(0xF)
    end

    if next_frame_number > SET_HOUR_FRAME and next_frame_number <= SET_HOUR_DONE_FRAME then
      BUTTON_RIGHT:set_value(0xF)
    end

    if next_frame_number > SET_HOUR_DONE_FRAME and next_frame_number <= SET_MINUTE_FRAME then
      BUTTON_UP:set_value(0xF)
    end

    if next_frame_number > SET_MINUTE_FRAME and next_frame_number <= SET_MINUTE_DONE_FRAME then
      BUTTON_ACTION:set_value(0xF)
    end

    if next_frame_number > CLOCK_READY_FRAME and next_frame_number <= APP_SELECTED_FRAME then
      BUTTON_RIGHT:set_value(0xF)
    end

    if next_frame_number > APP_LAUNCH_FRAME and next_frame_number <= APP_LAUNCHED_FRAME then
      BUTTON_ACTION:set_value(0xF)
    end
  end

  -- dump raw(ish) frame data to console!
  if next_frame_number > APP_LAUNCHED_FRAME then
    new_frame = read_display()

    if new_frame ~= LAST_FRAME then
      if LAST_FRAME then
        print(((frame_number - LAST_FRAME_NUMBER) / refresh_rate) .. '\n')
      end
      print(new_frame)
      --print('(frame delay: ' .. ((frame_number - LAST_FRAME_NUMBER) / refresh_rate) .. 's)')
      LAST_FRAME = new_frame
      LAST_FRAME_NUMBER = frame_number
    end
  end

  -- exit after GIF_TIME seconds of recording
  if next_frame_number > APP_LAUNCHED_FRAME + GIF_TIME * refresh_rate then
    --print('(final frame delay: ' .. ((frame_number - LAST_FRAME_NUMBER) / refresh_rate) .. 's)')
    os.exit()
  end
  emu.unpause()
end

emu.register_frame_done(on_frame_done)
