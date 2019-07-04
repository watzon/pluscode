require "./pluscode/code_area"
require "./pluscode/open_location_code"

module PlusCode
  extend PlusCode::OpenLocationCode

  # The character set used to encode coordinates.
  CODE_ALPHABET = "23456789CFGHJMPQRVWX"

  # The character used to pad a code
  PADDING = "0"

  # A separator used to separate the code into two parts.
  SEPARATOR = "+"

  # The max number of characters can be placed before the separator.
  SEPARATOR_POSITION = 8

  # Maximum number of digits to process in a plus code.
  MAX_CODE_LENGTH = 15

  # Maximum code length using lat/lng pair encoding. The area of such a
  # code is approximately 13x13 meters (at the equator), and should be suitable
  # for identifying buildings. This excludes prefix and separator characters.
  PAIR_CODE_LENGTH = 10_i64

  # Inverse of the precision of the pair code section.
  PAIR_CODE_PRECISION = 8000_i64

  # Precision of the latitude grid.
  LAT_GRID_PRECISION = 5_i64 ** (MAX_CODE_LENGTH - PAIR_CODE_LENGTH)

  # Precision of the longitude grid.
  LNG_GRID_PRECISION = 4_i64 ** (MAX_CODE_LENGTH - PAIR_CODE_LENGTH)

  # ASCII lookup table.
  DECODE = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
            nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
            nil, nil, nil, nil, nil,  -1, nil, nil, nil, nil,  -1, nil,   0,   1,   2,   3,   4,   5,   6,
              7, nil, nil, nil, nil, nil, nil, nil, nil, nil,   8, nil, nil,   9,  10,  11, nil,  12, nil,
            nil,  13, nil, nil,  14,  15,  16, nil, nil, nil,  17,  18,  19, nil, nil, nil, nil, nil, nil,
            nil, nil, nil, nil,   8, nil, nil,   9,  10,  11, nil,  12, nil, nil,  13, nil, nil,  14,  15,
             16, nil, nil, nil,  17,  18,  19]
end

puts PlusCode.shorten("8554R36H+RG", 33.8339114, -117.985578)
