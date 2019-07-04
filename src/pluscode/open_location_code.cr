module PlusCode
  # `OpenLocationCode` implements the Google Open Location Code(Plus+Codes)
  # algorithm.
  module OpenLocationCode
    extend self

    # Determines if a string is a valid sequence of Open Location Code
    # (Plus+Codes) characters.
    def valid?(code)
      valid_length?(code) && valid_separator?(code) && valid_padding?(code) &&
        valid_character?(code)
    end

    # Determines if a string is a valid short Open Location Code(Plus+Codes).
    def short?(code)
      valid?(code) && (code.index(SEPARATOR) || 0) < SEPARATOR_POSITION
    end

    # Determines if a string is a valid full Open Location Code(Plus+Codes).
    def full?(code)
      valid?(code) && !short?(code)
    end

    # Converts a latitude and longitude into a Open Location Code(Plus+Codes).
    def encode(latitude, longitude, code_length = PAIR_CODE_LENGTH)
      if invalid_length?(code_length)
        raise ArgumentError.new("Invalid Open Location Code(Plus+Codes) length")
      end

      code_length = MAX_CODE_LENGTH if code_length > MAX_CODE_LENGTH
      latitude = clip_latitude(latitude)
      longitude = normalize_longitude(longitude)
      latitude -= precision_by_length(code_length) if latitude == 90

      code = ""

      # Compute the code.
      # This approach converts each value to an integer after multiplying it by
      # the final precision. This allows us to use only integer operations, so
      # avoiding any accumulation of floating point representation errors.
      lat_val = 90_i64 * PAIR_CODE_PRECISION * LAT_GRID_PRECISION
      lat_val += latitude * PAIR_CODE_PRECISION * LAT_GRID_PRECISION
      lng_val = 180_i64 * PAIR_CODE_PRECISION * LNG_GRID_PRECISION
      lng_val += longitude * PAIR_CODE_PRECISION * LNG_GRID_PRECISION
      lat_val = lat_val.to_i64
      lng_val = lng_val.to_i64

      # Compute the grid part of the code if necessary.
      if code_length > PAIR_CODE_LENGTH
        (0..MAX_CODE_LENGTH - PAIR_CODE_LENGTH - 1).each do
          index = (lat_val % 5) * 4 + (lng_val % 4)
          code = CODE_ALPHABET[index] + code
          lat_val = lat_val / 5
          lng_val = lng_val / 4
        end
      else
        lat_val = lat_val / LAT_GRID_PRECISION
        lng_val = lng_val / LNG_GRID_PRECISION
      end
      (0..PAIR_CODE_LENGTH / 2 - 1).each do |i|
        code = CODE_ALPHABET[lng_val % 20] + code
        code = CODE_ALPHABET[lat_val % 20] + code
        lat_val = lat_val / 20
        lng_val = lng_val / 20
        code = '+' + code if i.zero?
      end

      # If we don't need to pad the code, return the requested section.
      return code[0, code_length + 1] if code_length >= SEPARATOR_POSITION

      # Pad and return the code.
      code[0, code_length] + PADDING * (SEPARATOR_POSITION - code_length) + "+"
    end

    # Decodes an Open Location Code(Plus+Codes) into a [CodeArea].
    #
    # @param code [String] a plus+codes
    # @return [CodeArea] a code area which contains the coordinates
    def decode(code)
      unless full?(code)
        raise ArgumentError.new("Open Location Code(Plus+Codes) is not a valid full code: #{code}")
      end

      code = code.gsub(SEPARATOR, "")
      code = code.gsub(/#{PADDING}+/, "")
      code = code.upcase

      south_latitude = -90.0
      west_longitude = -180.0

      lat_resolution = 400.to_f
      lng_resolution = 400.to_f

      digit = 0
      while digit < [code.size, MAX_CODE_LENGTH].min
        ord = DECODE[code[digit].ord] || 0

        if digit < PAIR_CODE_LENGTH
          lat_resolution /= 20
          lng_resolution /= 20
          south_latitude += lat_resolution * ord
          west_longitude += lng_resolution * (DECODE[code[digit + 1].ord] || 0)
          digit += 2
        else
          lat_resolution /= 5
          lng_resolution /= 4
          row = ord / 4
          column = ord % 4
          south_latitude += lat_resolution * row
          west_longitude += lng_resolution * column
          digit += 1
        end
      end

      CodeArea.new(south_latitude, west_longitude, lat_resolution,
                   lng_resolution, digit)
    end

    # Recovers a full Open Location Code(Plus+Codes) from a short code and a
    # reference location.
    def recover_nearest(short_code, reference_latitude, reference_longitude)
      return short_code.upcase if full?(short_code)

      unless short?(short_code)
        raise ArgumentError.new("Open Location Code(Plus+Codes) is not valid: #{short_code}")
      end

      ref_lat = clip_latitude(reference_latitude)
      ref_lng = normalize_longitude(reference_longitude)

      prefix_len = SEPARATOR_POSITION - (short_code.index(SEPARATOR) || 0)
      code = prefix_by_reference(ref_lat, ref_lng, prefix_len) + short_code
      code_area = decode(code)

      resolution = precision_by_length(prefix_len)
      half_res = resolution / 2

      latitude = code_area.latitude_center.to_f
      if ref_lat + half_res < latitude && latitude - resolution >= -90
        latitude -= resolution
      elsif ref_lat - half_res > latitude && latitude + resolution <= 90
        latitude += resolution
      end

      longitude = code_area.longitude_center.to_f
      if ref_lng + half_res < longitude
        longitude -= resolution
      elsif ref_lng - half_res > longitude
        longitude += resolution
      end

      encode(latitude, longitude, code.size - SEPARATOR.size)
    end

    # Removes four, six or eight digits from the front of an Open Location Code
    # (Plus+Codes) given a reference location.
    def shorten(code, latitude, longitude)
      unless full?(code)
        raise ArgumentError.new("Open Location Code(Plus+Codes) is a valid full code: #{code}")
      end
      unless code.index(PADDING).nil?
        raise ArgumentError.new("Cannot shorten padded codes: #{code}")
      end

      code_area = decode(code)
      lat_diff = (latitude - code_area.latitude_center.to_f).abs
      lng_diff = (longitude - code_area.longitude_center.to_f).abs
      max_diff = [lat_diff, lng_diff].max
      [8, 6, 4].each do |removal_len|
        area_edge = precision_by_length(removal_len) * 0.3
        return code[removal_len..-1] if max_diff < area_edge
      end

      code.upcase
    end

    private def prefix_by_reference(latitude, longitude, prefix_len)
      precision = precision_by_length(prefix_len)
      rounded_latitude = (latitude / precision).floor * precision
      rounded_longitude = (longitude / precision).floor * precision
      encode(rounded_latitude, rounded_longitude)[0...prefix_len]
    end

    private def narrow_region(digit, latitude, longitude)
      if digit.zero?
        latitude /= 20
        longitude /= 20
      elsif digit < PAIR_CODE_LENGTH
        latitude *= 20
        longitude *= 20
      else
        latitude *= 5
        longitude *= 4
      end
      [latitude, longitude]
    end

    private def build_code(digit_count, code, latitude, longitude)
      lat_digit = latitude.to_i
      lng_digit = longitude.to_i
      if digit_count < PAIR_CODE_LENGTH
        code << CODE_ALPHABET[lat_digit]
        code << CODE_ALPHABET[lng_digit]
        [digit_count + 2, latitude - lat_digit, longitude - lng_digit]
      else
        code << CODE_ALPHABET[4 * lat_digit + lng_digit]
        [digit_count + 1, latitude - lat_digit, longitude - lng_digit]
      end
    end

    private def valid_length?(code)
      !code.nil? && code.size >= 2 + SEPARATOR.size &&
        code.split(SEPARATOR).last.size != 1
    end

    private def valid_separator?(code)
      separator_idx = (code.index(SEPARATOR) || 0)
      code.count(SEPARATOR) == 1 && !separator_idx.nil? && separator_idx <= SEPARATOR_POSITION &&
        separator_idx.even?
    end

    private def valid_padding?(code)
      if code.includes?(PADDING)
        return false if (code.index(SEPARATOR) || 0) < SEPARATOR_POSITION
        return false if code.starts_with?(PADDING)
        return false if code[-2..-1] != PADDING + SEPARATOR

        paddings = code.scan(/#{PADDING}+/)
        return false if !paddings.one? || paddings[0][0].size.odd?
        return false if paddings[0][0].size > SEPARATOR_POSITION - 2
      end
      true
    end

    private def valid_character?(code)
      code.chars.each { |ch| return false if DECODE[ch.ord]?.nil? }
      true
    end

    private def invalid_length?(code_length)
      code_length < 2 || (code_length < PAIR_CODE_LENGTH && code_length.odd?)
    end

    private def padded(code)
      code << PADDING * (SEPARATOR_POSITION - code.size) << SEPARATOR
    end

    private def precision_by_length(code_length)
      if code_length <= PAIR_CODE_LENGTH
        return 20 ** ((code_length.to_f / -2) + 2)
      end

     1.0 / ((20 ** 3) * (5 ** (code_length - PAIR_CODE_LENGTH)))
    end

    private def clip_latitude(latitude)
      [90.0, [-90.0, latitude].max].min
    end

    private def normalize_longitude(longitude)
      until longitude < 180
        longitude -= 360
      end

      until longitude >= -180
        longitude += 360
      end

      longitude
    end
  end
end
