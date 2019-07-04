require "../spec_helper"
require "csv"

FIXTURES_PATH = File.expand_path("../fixtures", __DIR__)

FIXTURES = ["decoding", "encoding", "short_code", "validity"].reduce({} of String => CSV) do |acc, name|
  file_contents = File.read(File.join(FIXTURES_PATH, "#{name}.csv"))
  acc[name] = CSV.new(file_contents, headers: false)
  acc
end

describe PlusCode::OpenLocationCode do

  describe ".valid?" do
    it "checks if a plus code is valid" do
      FIXTURES["validity"].each do |line|
        code = line[0]
        is_valid = line[1] == "true"
        lc_is_valid = PlusCode.valid?(code)
        (lc_is_valid == is_valid).should be_true
      end
    end
  end

  describe ".short?" do
    it "checks if a plus code is short" do
      FIXTURES["validity"].each do |line|
        code = line[0]
        is_short = line[2] == "true"
        lc_is_short = PlusCode.short?(code)
        (lc_is_short == is_short).should be_true
      end
    end
  end

  describe ".full?" do
    it "checks if a plus code is full" do
      FIXTURES["validity"].each do |line|
        code = line[0]
        is_full  = line[3] == "true"
        lc_is_full  = PlusCode.full?(code)
        (lc_is_full  == is_full ).should be_true
      end
    end
  end

  describe ".decode" do
    it "should decode a plus code" do
      FIXTURES["decoding"].each do |line|
        code_area = PlusCode.decode(line[0])
        line[1].to_i.should eq code_area.code_length

        # Check returned coordinates are within 1e-10 of expected.
        precision = 1e-10
        ((code_area.south_latitude - line[2].to_f).abs < precision).should be_true
        ((code_area.west_longitude - line[3].to_f).abs < precision).should be_true
        ((code_area.north_latitude - line[4].to_f).abs < precision).should be_true
        ((code_area.east_longitude - line[5].to_f).abs < precision).should be_true
      end
    end

    it "should raise with an invalid code" do
      expect_raises(ArgumentError) do
        PlusCode.decode("sfdg")
      end
    end
  end

  describe ".encode" do
    it "should encode a latitude and longitude" do
      FIXTURES["encoding"].each do |line|
        code = PlusCode.encode(line[0].to_f, line[1].to_f, line[2].to_i)
        code.should eq line[3]
      end
    end

    it "should work with longer encoding" do
      PlusCode.encode(90.0, 1.0, 15).should eq "CFX3X2X2+X2RRRRR"
    end

    it "should raise argument error on invalid code length" do
      expect_raises(ArgumentError) do
        PlusCode.encode(20, 30, 1)
      end

      expect_raises(ArgumentError) do
        PlusCode.encode(20, 30, 9)
      end
    end
  end

  describe ".shorten" do
    it "should shorten a plus code" do
      FIXTURES["short_code"].each do |line|
        code = line[0]
        lat = line[1].to_f
        lng = line[2].to_f
        short_code = line[3]
        test_type = line[4]

        if ["B", "S"].includes?(test_type)
          short = PlusCode.shorten(code, lat, lng)
          short_code.should eq short
        end

        if ["B", "R"].includes?(test_type)
          expanded = PlusCode.recover_nearest(short_code, lat, lng)
          code.should eq expanded
        end
      end
    end

    it "should raise with an invalid code" do
      expect_raises(ArgumentError) do
        PlusCode.recover_nearest("9C3W9QCJ-2VX", 51.3708675, -1.217765625)
      end

      expect_raises(ArgumentError) do
        PlusCode.shorten("9C3W9Q+", 1, 2)
      end

      expect_raises(ArgumentError) do
        PlusCode.shorten("9C3W9Q00+", 1, 2)
      end

      PlusCode.recover_nearest("9C3W9QCJ+2VX", 51.3708675, -1.217765625)
    end
  end

  unless ENV["NO_BENCHMARK"]?
    describe "benchmarks" do
      test_data = [] of Tuple(Float64, Float64, Int32, String)

      100000.times do
        exp = 10.0 ** rand(10)
        lat = ((rand * 180 - 90) * exp).round / exp
        lng = ((rand * 360 - 180) * exp).round / exp
        len = rand(15)
        len = rand(1..5) * 2 if len <= 10

        test_data.push({lat, lng, len, PlusCode.encode(lat, lng, len)})
      end

      elapsed_time = Time.measure do
        test_data.each do |lat, lng, len, _|
          PlusCode.encode(lat, lng, len)
        end
      end

      printf("\n\nEncode benchmark: %d μsec total, %d loops, %f μsec per call\n",
        elapsed_time.microseconds, test_data.size,
        elapsed_time.microseconds.to_f / test_data.size)

      elapsed_time = Time.measure do
        test_data.each do |_, _, _, code|
          PlusCode.decode(code)
        end
      end

      printf("\nDecode benchmark: %d μsec total, %d loops, %f μsec per call\n",
           elapsed_time.microseconds, test_data.size,
           elapsed_time.microseconds.to_f / test_data.size)
    end
  end
end
