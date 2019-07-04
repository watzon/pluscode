# PlusCode

PlusCode is a Crystal implementation of the [Open Location Code](https://www.wikiwand.com/en/Open_Location_Code) spec.

> The Open Location Code (OLC) is a geocode system for identifying an area anywhere on the Earth.[1] It was developed at Google's Zürich engineering office, and released late October 2014. Location codes created by the OLC system are referred to as "plus codes". - Wikipedia

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     pluscode:
       github: watzon/pluscode
   ```

2. Run `shards install`

3. Require it in your project
   
   ```crystal
   require "pluscode
   ```

## Usage

### Encoding

Pluscodes can be created from a latitude and longitude. For instance, {33.8120918, -117.9211629} are the coordinates for Disneyland Park in Anaheim, California. To generate a location code for Disneyland:

```crystal
code = PlusCode.encode(33.8120918, -117.9211629)
puts code
# => 8554R36H+RG
```

If you want a shorter or longer code you can also supply a code length as the third parameter:

```crystal
code = PlusCode.encode(33.8120918, -117.9211629, 4)
puts code
# => 85540000+

code = PlusCode.encode(33.8120918, -117.9211629, 15)
puts code
# => 8554R36H+RGPQ6W3
```

Remeber that the longer the code length (up to 15), the more accurate it will be. The minimum code length is 2.

### Decoding

You can also decode a pluscode back into a `CodeArea` (an object that represents a latitude, longitude, and their accuracy). To get the latitude and longitude back from our Disneyland code:

```crystal
area = PlusCode.decode("8554R36H+RGPQ6W3")
pp area
# => #<PlusCode::CodeArea:0x7fd2cd63ee00
# =>             @code_length=15,
# =>             @latitude_center=4758628878786531/140737488355328,
# =>             @latitude_height=4.000000000000001e-8,
# =>             @longitude_center=-8297964145442029/70368744177664,
# =>             @longitude_width=1.220703125e-7,
# =>             @south_latitude=33.8120918,
# =>             @west_longitude=-117.92116296386718>
```

### Expanding a short code

It is possible to convert a short code into it's full expanded form given a reference location. For instance, given the extremely short code `R36H+RG`, you can expand it with:

```crystal
expanded_code = PlusCode.recover_nearest("R36H+RG", 33.8339114, -117.985578)
puts expanded_code
# => 8554R36H+RG
```

### Shortening a longer code

You can also shorten a code to a regional one given a code, latitude, and longitude. For instance `8554R36H+RG` was the code for Disneyland, but if you want to shorten it to a code that can be used within Anaheim which has the coordinates {33.8339114, -117.985578} you could do:

```crystal
shortened_code = PlusCode.shorten("8554R36H+RG", 33.8339114, -117.985578)
puts shortened_code
# => R36H+RG
```

## Benchmarks

This Crystal implementation is orders of maginitude faster than the very similar Ruby implementation located [here](https://github.com/google/open-location-code). Here are my results:


```
Ruby

Encode benchmark: 696117 usec total,  100000 loops, 6.961170  usec per call
Decode benchmark: 3617958 usec total, 100000 loops, 36.179580 usec per call

Crystal

Encode benchmark: 234487 μsec total,  100000 loops, 2.344870  μsec per call
Decode benchmark: 356371 μsec total,  100000 loops, 3.563710  μsec per call
```

## Contributing

1. Fork it (<https://github.com/watzon/pluscode/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
