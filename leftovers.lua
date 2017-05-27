-- Stuff that was cute to play with but ultimately not used in CrashStation! proper

CENTURY_OFFSET = 0x00000cf
DATE_OFFSET    = 0xb80000c
TIME_OFFSET    = 0xb800008

function read_date()
  cent = program_memory:read_u8(CENTURY_OFFSET)

  century = ((cent & 0x000000f0) >> 4) .. (cent & 0x0000000f)

  date = program_memory:read_u32(DATE_OFFSET)

  year = ((date & 0x00f00000) >> 20) .. ((date & 0x000f0000) >> 16)
  month = ((date & 0x0000f000) >> 12) .. ((date & 0x00000f00) >> 8)
  day = ((date & 0x000000f0) >> 4) .. (date & 0x0000000f)

  return century .. year .. '/' .. month .. '/' .. day
end

function read_time()
  time = program_memory:read_u32(TIME_OFFSET)

  hour = ((time & 0x00f00000) >> 20) .. ((time & 0x000f0000) >> 16)
  minute = ((time & 0x0000f000) >> 12) .. ((time & 0x00000f00) >> 8)
  second = ((time & 0x000000f0) >> 4) .. (time & 0x0000000f)

  return hour .. ':' .. minute .. ':' .. second
end

function read_weekday()
  time = program_memory:read_u32(TIME_OFFSET)

  return ((time & 0x0f000000) >> 24) -- starts on sunday
end
