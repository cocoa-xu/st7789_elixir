defmodule :st7789_nif do
  @moduledoc false
  @on_load :load_nif
  def load_nif do
    nif_file = '#{:code.priv_dir(:st7789_elixir)}/st7789'

    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> IO.puts("Failed to load nif: #{inspect(reason)}")
    end
  end

  def to_rgb565(_image_data, _colorspace), do: :erlang.nif_error(:not_loaded)
end
