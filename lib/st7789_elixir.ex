defmodule ST7789 do
  @moduledoc false

  use Bitwise

  @enforce_keys [:spi, :gpio]
  defstruct [:spi, :gpio, :opts]

  @doc """
  New connection to an ST7789

  - **port**: SPI port number
  - **cs**: SPI chip-select number (0 or 1 for BCM
  - **backlight**: Pin for controlling backlight
  - **rst**: Reset pin for ST7789
  - **width**: Width of display connected to ST7789
  - **height**: Height of display connected to ST7789
  - **offset_top**: Offset to top row
  - **offset_left**: Offset to left column
  - **invert**: Invert display
  - **speed_hz**: SPI speed (in Hz)

  ## Example
  port = 0
  dc = 9
  backlight = 19
  speed_hz = 80 * 1000 * 1000
  ST7789.new(port, dc, backlight: backlight, speed_hz: speed_hz)
  """
  def new(port, dc, opts \\ []) when port >= 0 and dc >= 0 do
    cs = opts[:cs]                    || kBG_SPI_CS_FRONT()
    speed_hz = opts[:speed_hz]        || 400_0000
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
        cs: cs,
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
  """
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
  Write the provided image to the hardware.

  - image_data: List: Should be RGB format and the same dimensions (width x height x 3) as the display hardware.
  - image_data: binary: Should be 16bit RGB565 format and the same dimensions (width x height x 3) as the display hardware.
  """
  def display(self, image_data, convert)
  def display(self, image_data, true) when is_list(image_data) do
    display(self, to_rgb565(image_data))
  end
  def display(self, image_data, false) when is_list(image_data) do
    self
      |> set_window(x0: 0, y0: 0, x1: nil, y2: nil)
      |> send(image_data, true, 4096)
  end
  def display(self, image_data) when is_binary(image_data) do
    display(self, :binary.bin_to_list(image_data), false)
  end

  defp to_rgb565(image_data) when is_list(image_data) do
    image_data
      |> Enum.chunk_every(3)
      |> Enum.map(fn [r,g,b] ->
        bor(
          bor(
            bsl(band(r, 0xF8), 8),
            bsl(band(g, 0xFC), 3)),
            bsr(band(b, 0xF8), 3))
        end)
      |> Enum.into(<<>>, fn bit -> <<bit :: 16>> end)
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
    IO.inspect(width)
    height = board[:height]
    IO.inspect(height)
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

  defp command(self, cmd) when is_integer(cmd) do
    # Write a byte or array of bytes to the display as command data.
    send(self, cmd, false)
  end

  defp data(self, data) do
    # Write a byte or array of bytes to the display as display data.
    send(self, data, true)
  end

  defp send(self, data, is_data, chunk_size \\ 4096)
  defp send(self, data, true, chunk_size) do
    send(self, data, 1, chunk_size)
  end
  defp send(self, data, false, chunk_size) do
    send(self, data, 0, chunk_size)
  end
  defp send(self, data, is_data, chunk_size)
  when (is_data == 0 or is_data == 1) and is_integer(data) do
    send(self, [Bitwise.band(data, 0xFF)], is_data, chunk_size)
  end
  defp send(self=%ST7789{gpio: gpio, spi: spi}, data, is_data, chunk_size)
  when (is_data == 0 or is_data == 1) and is_list(data) do
    gpio_dc = gpio[:dc]
    if gpio_dc != nil do
      Circuits.GPIO.write(gpio_dc, is_data)
      for xfdata <-
        data
        |> Enum.chunk_every(chunk_size)
        |> Enum.map(& Enum.into(&1, <<>>, fn bit -> <<bit :: 8>> end)) do
          {:ok, _ret} = Circuits.SPI.transfer(spi, xfdata)
      end
      self
    else
      {:error, "gpio[:dc] is nil"}
    end
  end

  def kBG_SPI_CS_BACK,  do: 0
  def kBG_SPI_CS_FRONT, do: 1

  def kSWRESET,         do: 0x01

  def kSLPOUT,          do: 0x11

  def kINVOFF,          do: 0x20
  def kINVON,           do: 0x21
  def kDISPON,          do: 0x29

  def kCASET,           do: 0x2A
  def kRASET,           do: 0x2B
  def kRAMWR,           do: 0x2C

  def kMADCTL,          do: 0x36
  def kCOLMOD,          do: 0x3A

  def kFRMCTR2,         do: 0xB2

  def kGCTRL,           do: 0xB7
  def kVCOMS,           do: 0xBB

  def kLCMCTRL,         do: 0xC0
  def kVDVVRHEN,        do: 0xC2
  def kVRHS,            do: 0xC3
  def kVDVS,            do: 0xC4
  def kFRCTRL2,         do: 0xC6

  def kGMCTRP1,         do: 0xE0
  def kGMCTRN1,         do: 0xE1
end
