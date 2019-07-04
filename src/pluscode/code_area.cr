require "big"

module PlusCode
  # `CodeArea` contains coordinates of a decoded Open Location Code(Plus+Codes).
  # The coordinates include the latitude and longitude of the lower left and
  # upper right corners and the center of the bounding box for the area the
  # code represents.
  class CodeArea

    property south_latitude : Float64

    property west_longitude : Float64

    property latitude_height : Float64

    property longitude_width : Float64

    property code_length : Int32

    getter latitude_center : BigRational

    getter longitude_center : BigRational

    # Creates a `CodeArea`
    def initialize(@south_latitude, @west_longitude, @latitude_height,
      @longitude_width, @code_length)
      @latitude_center = (south_latitude + latitude_height / 2.0).to_big_r
      @longitude_center = (west_longitude + longitude_width / 2.0).to_big_r
    end

    def north_latitude
      @south_latitude + @latitude_height
    end

    def east_longitude
      @west_longitude + @longitude_width
    end
  end
end
