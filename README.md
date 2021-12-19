# ST7789-Elixir

ST7789 driver for Elixir.

Tested on my 1.3" SPI Colour Square LCD (240x240) Breakout.

## Example
### PIN connection

| ST7789 | Raspberry Pi       | Variable      |
|--------|--------------------|---------------|
| 3-5V   | Any 5V or 3.3V PIN | N/A           |
| CS     | BCM 7 / BCM 8      | cs: 1 / cs: 0 |
| SCK    | BCM 11             | N/A           |
| MOSI   | BCM 10             | N/A           |
| DC     | BCM 9              | dc: 9         |
| BL     | BCM 19             | backlight: 19 |
| GND    | Any ground PIN     | N/A           |

### Code
```elixir
# init ST7789 screen
port = 0
dc = 9
backlight = 19
speed_hz = 80 * 1000 * 1000
disp = ST7789.new(port, dc: dc, backlight: backlight, speed_hz: speed_hz)

# read image from file
{:ok, mat} = OpenCV.imread("/path/to/some/image")
# convert to rgb888 colorspace
{:ok, mat} = OpenCV.cvtcolor(mat, OpenCV.cv_color_bgr2rgb)
# to binary
{:ok, image_data} = OpenCV.Mat.to_binary(mat)
# display it
ST7789.display(disp, image_data)

# open video stream
{:ok, cap} = OpenCV.VideoCapture.videocapture(0)
# read a frame
{:ok, mat} = OpenCV.VideoCapture.read(cap)
# convert to rgb888 colorspace
{:ok, mat} = OpenCV.cvtcolor(mat, OpenCV.cv_color_bgr2rgb)
# resize to 240x240
{:ok, mat} = OpenCV.resize(mat, [240, 240])
# to binary
{:ok, image_data} = OpenCV.Mat.to_binary(mat)
# display it
ST7789.display(disp, image_data)
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `st7789_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:st7789_elixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/st7789_elixir](https://hexdocs.pm/st7789_elixir).

