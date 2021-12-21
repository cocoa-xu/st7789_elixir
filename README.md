# ST7789-Elixir

ST7789 driver for Elixir.

Tested on my 1.3" SPI Colour Square LCD (240x240) Breakout.

## Example
### PIN connection

| ST7789 | Raspberry Pi       | Variable      | Description |
|--------|--------------------|---------------|-------------|
| 3-5V   | Any 5V or 3.3V PIN | N/A           | VCC         |
| CS     | BCM 8 / BCM 7      | cs: 0 / cs: 1 | CE 0 / CE 1 |
| SCK    | BCM 11             | N/A           | SCLK        |
| MOSI   | BCM 10             | N/A           | MOSI        |
| DC     | BCM 9              | dc: 9         | MISO        |
| BL     | BCM 17 / BCM 27    | backlight: 17 / backlight: 27 | Backlight |
| GND    | Any ground PIN     | N/A           | Ground      |

### Code
```elixir
# init ST7789 screen
port = 0                        # spi bus 0
speed_hz = 80 * 1000 * 1000     # 80MHz
dc = 9                          # MISO PIN 9

# first display
cs1 = 0                         # BCM 8 / CE 0
backlight1 = 17                 # BCM 17
disp1 = ST7789.new(port, cs: cs1, backlight: backlight1, dc: dc, speed_hz: speed_hz)

# second display
cs2 = 1                         # BCM 7 / CE 1
backlight2 = 27                 # BCM 27
disp2 = ST7789.new(port, cs: cs2, backlight: backlight2, dc: dc, speed_hz: speed_hz)

# read image from file
{:ok, mat} = OpenCV.imread("/path/to/some/image")
# convert to rgb888 colorspace
{:ok, mat} = OpenCV.cvtcolor(mat, OpenCV.cv_color_bgr2rgb)
# to binary
{:ok, image_data} = OpenCV.Mat.to_binary(mat)
# display it
ST7789.display(disp1, image_data)
ST7789.display(disp2, image_data)

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
ST7789.display(disp1, image_data)
ST7789.display(disp2, image_data)

# turn off/on backlight
ST7789.set_backlight(disp1, :off)
ST7789.set_backlight(disp1, :on)
ST7789.set_backlight(disp2, :off)
ST7789.set_backlight(disp2, :on)
```

## Installation

The package can be installed by adding `st7789_elixir` to your list of dependencies in `mix.exs`:

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

