defmodule ST7789 do
  @moduledoc """
  ST7789 Elixir driver
  """

  use Bitwise

  @enforce_keys [:spi, :gpio, :opts]
  defstruct [:spi, :gpio, :opts]

  @doc """
  New connection to an ST7789

  - **port**: SPI port number

    Default value: `0`

  - **cs**: SPI chip-select number (0 or 1 for BCM).

    Default value: `0`.

  - **dc**: Command/data register selection

    Default value: `9`.

  - **backlight**: Pin for controlling backlight

    Default value: `nil`.

  - **rst**: Reset pin for ST7789

    Default value: `nil`.

  - **width**: Width of display connected to ST7789

    Default value: `240`.

  - **height**: Height of display connected to ST7789

    Default value: `240`.

  - **offset_top**: Offset to top row

    Default value: `0`.

  - **offset_left**: Offset to left column

    Default value: `0`.

  - **invert**: Invert display

    Default value: `true`.

  - **speed_hz**: SPI speed (in Hz)

    Default value: `400_0000`.

  **return**: `%ST7789{}`

  ## Example
  ```elixir
  # default
  # assuming device at /dev/spidev0.0
  # DC connects to BCM 9
  # BL not connected
  # RST not connected
  # SPI speed: 4MHz
  disp = ST7789.new()
  ```

  ```elixir
  # specify init arguments
  port = 0                      # spi bus 0
  cs = 0                        # BCM 8 / CE 0
  dc = 9                        # BCM 9
  backlight = 17                # BCM 17
  speed_hz = 80 * 1000 * 1000   # 80MHz
  disp = ST7789.new(port: port, cs: cs, dc: dc, backlight: backlight, speed_hz: speed_hz)
  ```
  """
  @doc functions: :exported
  def new(opts \\ []) do
    port = opts[:port]                || 0
    cs = opts[:cs]                    || 0
    dc = opts[:dc]                    || 9
    speed_hz = opts[:speed_hz]        || 4_000_000
    invert = opts[:invert]            || true
    width = opts[:width]              || 240
    height = opts[:height]            || 240
    offset_top = opts[:offset_top]    || 0
    offset_left = opts[:offset_left]  || 0
    backlight = opts[:backlight]
    rst = opts[:rst]

    {:ok, spi} = Circuits.SPI.open("spidev#{port}.#{cs}", speed_hz: speed_hz)

    # Set DC as output.
    {:ok, gpio_dc} = Circuits.GPIO.open(dc, :output)

    # Setup backlight as output (if provided).
    gpio_backlight = init_backlight(backlight)

    # Setup reset as output (if provided).
    gpio_rst = init_reset(rst)

    %ST7789{
      spi: spi,
      gpio: [
        dc:        gpio_dc,
        backlight: gpio_backlight,
        rst:       gpio_rst
      ],
      opts: [
        port: port,
        cs: cs,
        dc: dc,
        speed_hz: speed_hz,
        invert: invert,
        width: width,
        height: height,
        offset_top: offset_top,
        offset_left: offset_left,
        backlight: backlight,
        rst: rst
      ]
    }
    |> ST7789.reset()
    |> init()
  end

  @doc """
  Reset the display, if reset pin is connected.

  - **self**: `%ST7789{}`

  **return**: `self`
  """
  @doc functions: :exported
  def reset(self=%ST7789{gpio: gpio}) do
    gpio_rst = gpio[:rst]
    if gpio_rst != nil do
      Circuits.GPIO.write(gpio_rst, 1)
      :timer.sleep(500)
      Circuits.GPIO.write(gpio_rst, 0)
      :timer.sleep(500)
      Circuits.GPIO.write(gpio_rst, 1)
      :timer.sleep(500)
    end
    self
  end

  @doc """
  Write the provided 16bit RGB565 image to the hardware.

  - **self**: `%ST7789{}`
  - **image_data**: Should be 16bit RGB565 format and the same dimensions (width x height x 3) as the display hardware.

  **return**: `self`
  """
  @doc functions: :exported
  def display_rgb565(self, image_data) when is_binary(image_data) do
    display_rgb565(self, :binary.bin_to_list(image_data))
  end
  def display_rgb565(self, image_data) when is_list(image_data) do
    self
      |> set_window(x0: 0, y0: 0, x1: nil, y2: nil)
      |> send(image_data, true, 4096)
  end

  @doc """
  Write the provided 24bit BGR888/RGB888 image to the hardware.

  - **self**: `%ST7789{}`
  - **image_data**: Should be 24bit BGR888/RGB888 format and the same dimensions (width x height x 3) as the display hardware.
  - **channel_order**: either `:rgb` or `:bgr`

  **return**: `self`
  """
  @doc functions: :exported
  def display(self, image_data, channel_order)
  when is_binary(image_data) and (channel_order == :rgb or channel_order == :bgr) do
    display_rgb565(self, to_rgb565(image_data, channel_order))
  end
  def display(self, image_data, channel_order)
  when is_list(image_data) and (channel_order == :rgb or channel_order == :bgr) do
    display(self, Enum.map(image_data, & Enum.into(&1, <<>>, fn bit -> <<bit :: 8>> end)), channel_order)
  end

  @doc """
  Set backlight status

  - **self**: `%ST7789{}`
  - **status**: either `:on` or `:off`

  **return**: `self`
  """
  @doc functions: :exported
  def set_backlight(self=%ST7789{gpio: gpio}, :on) do
    backlight = gpio[:backlight]
    if backlight != nil do
      Circuits.GPIO.write(backlight, 1)
    end
    self
  end
  def set_backlight(self=%ST7789{gpio: gpio}, :off) do
    backlight = gpio[:backlight]
    if backlight != nil do
      Circuits.GPIO.write(backlight, 0)
    end
    self
  end

  @doc """
  Get screen size

  - **self**: `%ST7789{}`

  **return**: `%{height: height, width: width}`
  """
  @doc functions: :exported
  def size(%ST7789{opts: opts}) do
    %{height: opts[:height], width: opts[:width]}
  end

  @doc """
  Write a byte to the display as command data.

  - **self**: `%ST7789{}`
  - **cmd**: command data

  **return**: `self`
  """
  @doc functions: :exported
  def command(self, cmd) when is_integer(cmd) do
    send(self, cmd, false)
  end

  @doc """
  Write a byte or array of bytes to the display as display data.

  - **self**: `%ST7789{}`
  - **data**: display data

  **return**: `self`
  """
  @doc functions: :exported
  def data(self, data) do
    send(self, data, true)
  end

  @doc """
  Send bytes to the ST7789

  - **self**: `%ST7789{}`
  - **bytes**: The bytes to be sent to `self`

    - `when is_integer(bytes)`,
      `sent` will take the 8 least-significant bits `[band(bytes, 0xFF)]`
      and send it to `self`
    - `when is_list(bytes)`, `bytes` will be casting to bitstring and then sent
      to `self`

  - **is_data**:

    - `true`: `bytes` will be sent as data
    - `false`: `bytes` will be sent as commands

  - **chunk_size**: Indicates how many bytes will be send in a single write call

  **return**: `self`
  """
  @doc functions: :exported
  def send(self, bytes, is_data, chunk_size \\ 4096)
  def send(self=%ST7789{}, bytes, true, chunk_size) do
    send(self, bytes, 1, chunk_size)
  end
  def send(self=%ST7789{}, bytes, false, chunk_size) do
    send(self, bytes, 0, chunk_size)
  end
  def send(self=%ST7789{}, bytes, is_data, chunk_size)
  when (is_data == 0 or is_data == 1) and is_integer(bytes) do
    send(self, [Bitwise.band(bytes, 0xFF)], is_data, chunk_size)
  end
  def send(self=%ST7789{gpio: gpio, spi: spi}, bytes, is_data, chunk_size)
  when (is_data == 0 or is_data == 1) and is_list(bytes) do
    gpio_dc = gpio[:dc]
    if gpio_dc != nil do
      Circuits.GPIO.write(gpio_dc, is_data)
      for xfdata <-
        bytes
        |> Enum.chunk_every(chunk_size)
        |> Enum.map(& Enum.into(&1, <<>>, fn bit -> <<bit :: 8>> end)) do
          {:ok, _ret} = Circuits.SPI.transfer(spi, xfdata)
      end
      self
    else
      {:error, "gpio[:dc] is nil"}
    end
  end

  defp to_rgb565(image_data, channel_order)
  when is_binary(image_data) and (channel_order == :rgb or channel_order == :bgr) do
    image_data
      |> :st7789_nif.to_565(channel_order, :rgb)   # ST7789 always uses RGB565 format
      |> :binary.bin_to_list()

    # elixir implementation is slower
    # image_data
    #  |> :binary.bin_to_list()
    #  |> Enum.chunk_every(3)
    #  |> Enum.map(fn [b,g,r] ->
    #    bor(
    #      bor(
    #        bsl(band(r, 0xF8), 8),
    #        bsl(band(g, 0xFC), 3)),
    #      bsr(band(b, 0xF8), 3))
    #  end)
    #  |> Enum.into(<<>>, fn bit -> <<bit :: 16>> end)
    #  |> :binary.bin_to_list()
  end

  defp init(self=%ST7789{opts: board}) do
    invert = board[:invert]

    # Initialize the display.
    command(self, kSWRESET())   # Software reset
    :timer.sleep(150)           # delay 150 ms

    self
      |> command(kMADCTL())
      |> data(0x70)
      |> command(kFRMCTR2())
      |> data(0x0C)
      |> data(0x0C)
      |> data(0x00)
      |> data(0x33)
      |> data(0x33)
      |> command(kCOLMOD())
      |> data(0x05)
      |> command(kGCTRL())
      |> data(0x14)
      |> command(kVCOMS())
      |> data(0x37)
      |> command(kLCMCTRL())  # Power control
      |> data(0x2C)
      |> command(kVDVVRHEN()) # Power control
      |> data(0x01)
      |> command(kVRHS())     # Power control
      |> data(0x12)
      |> command(kVDVS())     # Power control
      |> data(0x20)
      |> command(0xD0)
      |> data(0xA4)
      |> data(0xA1)
      |> command(kFRCTRL2())
      |> data(0x0F)
      |> command(kGMCTRP1())  # Set Gamma
      |> data(0xD0)
      |> data(0x04)
      |> data(0x0D)
      |> data(0x11)
      |> data(0x13)
      |> data(0x2B)
      |> data(0x3F)
      |> data(0x54)
      |> data(0x4C)
      |> data(0x18)
      |> data(0x0D)
      |> data(0x0B)
      |> data(0x1F)
      |> data(0x23)
      |> command(kGMCTRN1())  # Set Gamma
      |> data(0xD0)
      |> data(0x04)
      |> data(0x0C)
      |> data(0x11)
      |> data(0x13)
      |> data(0x2C)
      |> data(0x3F)
      |> data(0x44)
      |> data(0x51)
      |> data(0x2F)
      |> data(0x1F)
      |> data(0x1F)
      |> data(0x20)
      |> data(0x23)
      |> init_invert(invert)
      |> command(kSLPOUT())
      |> command(kDISPON())
    :timer.sleep(100)
    self
  end

  defp init_backlight(nil), do: nil
  defp init_backlight(backlight) when backlight >= 0 do
    {:ok, gpio} = Circuits.GPIO.open(backlight, :output)
    Circuits.GPIO.write(gpio, 0)
    :timer.sleep(100)
    Circuits.GPIO.write(gpio, 1)
    gpio
  end
  defp init_backlight(_), do: nil

  defp init_reset(nil), do: nil
  defp init_reset(rst) when rst >= 0 do
    {:ok, gpio} = Circuits.GPIO.open(rst, :output)
    gpio
  end
  defp init_reset(_), do: nil

  defp init_invert(self, true) do
    # Invert display
    command(self, kINVON())
  end
  defp init_invert(self, _) do
    # Don't invert display
    command(self, kINVOFF())
  end

  defp set_window(self=%ST7789{opts: board}, opts = [x0: 0, y0: 0, x1: nil, y2: nil]) do
    width = board[:width]
    height = board[:height]
    offset_top = board[:offset_top]
    offset_left = board[:offset_left]
    x0 = opts[:x0]
    x1 = opts[:x1]
    x1 = if x1 == nil, do: width - 1
    y0 = opts[:y0]
    y1 = opts[:y1]
    y1 = if y1 == nil, do: height - 1
    y0 = y0 + offset_top
    y1 = y1 + offset_top
    x0 = x0 + offset_left
    x1 = x1 + offset_left

    self
      |> command(kCASET())
      |> data(bsr(x0, 8))
      |> data(band(x0, 0xFF))
      |> data(bsr(x1, 8))
      |> data(band(x1, 0xFF))
      |> command(kRASET())
      |> data(bsr(y0, 8))
      |> data(band(y0, 0xFF))
      |> data(bsr(y1, 8))
      |> data(band(y1, 0xFF))
      |> command(kRAMWR())
  end

  @doc functions: :constants
  def kSWRESET,         do: 0x01

  @doc functions: :constants
  def kSLPOUT,          do: 0x11

  @doc functions: :constants
  def kINVOFF,          do: 0x20
  @doc functions: :constants
  def kINVON,           do: 0x21
  @doc functions: :constants
  def kDISPON,          do: 0x29

  @doc functions: :constants
  def kCASET,           do: 0x2A
  @doc functions: :constants
  def kRASET,           do: 0x2B
  @doc functions: :constants
  def kRAMWR,           do: 0x2C

  @doc functions: :constants
  def kMADCTL,          do: 0x36
  @doc functions: :constants
  def kCOLMOD,          do: 0x3A

  @doc functions: :constants
  def kFRMCTR2,         do: 0xB2

  @doc functions: :constants
  def kGCTRL,           do: 0xB7
  @doc functions: :constants
  def kVCOMS,           do: 0xBB

  @doc functions: :constants
  def kLCMCTRL,         do: 0xC0
  @doc functions: :constants
  def kVDVVRHEN,        do: 0xC2
  @doc functions: :constants
  def kVRHS,            do: 0xC3
  @doc functions: :constants
  def kVDVS,            do: 0xC4
  @doc functions: :constants
  def kFRCTRL2,         do: 0xC6

  @doc functions: :constants
  def kGMCTRP1,         do: 0xE0
  @doc functions: :constants
  def kGMCTRN1,         do: 0xE1
end
