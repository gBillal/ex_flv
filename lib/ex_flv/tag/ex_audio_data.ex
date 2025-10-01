defmodule ExFLV.Tag.ExAudioData do
  @moduledoc """
  Module describing an enhanced audio data tag.
  """

  @type fourcc :: :ac3 | :eac3 | :opus | :mp3 | :flac | :aac
  @type channel_order :: :unspecified | :native | :custom

  @type packet_type ::
          :sequence_start
          | :coded_frames
          | :sequence_end
          | :multi_channel_config
          | :multi_track
          | :mod_ex

  @type channel ::
          :front_left
          | :front_right
          | :front_center
          | :low_frequency1
          | :back_left
          | :back_right
          | :front_left_center
          | :front_right_center
          | :back_center
          | :side_left
          | :side_right
          | :top_center
          | :top_front_left
          | :top_front_center
          | :top_front_right
          | :top_back_left
          | :top_back_center
          | :top_back_right
          | :low_frequency2
          | :top_side_left
          | :top_side_right
          | :bottom_front_center
          | :bottom_front_left
          | :bottom_front_right
          | :unused
          | :unknown

  @type t :: %__MODULE__{
          packet_type: packet_type(),
          fourcc: fourcc(),
          channel_order: channel_order() | nil,
          channel_count: non_neg_integer() | nil,
          channels: list(channel()) | nil,
          data: iodata()
        }

  defstruct [:packet_type, :fourcc, :channel_order, :channel_count, :channels, :data]

  @audio_channels %{
    0 => :front_left,
    1 => :front_right,
    2 => :front_center,
    3 => :low_frequency1,
    4 => :back_left,
    5 => :back_right,
    6 => :front_left_center,
    7 => :front_right_center,
    8 => :back_center,
    9 => :side_left,
    10 => :side_right,
    11 => :top_center,
    12 => :top_front_left,
    13 => :top_front_center,
    14 => :top_front_right,
    15 => :top_back_left,
    16 => :top_back_center,
    17 => :top_back_right,
    18 => :low_frequency2,
    19 => :top_side_left,
    20 => :top_side_right,
    21 => :bottom_front_center,
    22 => :bottom_front_left,
    23 => :bottom_front_right,
    254 => :unused,
    255 => :unknown
  }

  @doc """
  Parses the binary into an enhanced audio data tag.

  ## Examples

      iex> ExFLV.Tag.ExAudioData.parse(<<148, 102, 76, 97, 67, 1, 2, 0, 0, 0, 3>>)
      {:ok,
       %ExFLV.Tag.ExAudioData{
         packet_type: :multi_channel_config,
         fourcc: :flac,
         channel_order: :native,
         channel_count: 2,
         channels: [:front_left, :front_right],
         data: <<>>
       }}

      iex> ExFLV.Tag.ExAudioData.parse(<<145, 109, 112, 52, 97, 255, 248, 89, 174, 0, 90, 78, 0>>)
      {:ok,
       %ExFLV.Tag.ExAudioData{
         packet_type: :coded_frames,
         fourcc: :aac,
         channel_order: nil,
         channel_count: nil,
         channels: nil,
         data: <<255, 248, 89, 174, 0, 90, 78, 0>>
       }}

      iex> ExFLV.Tag.ExAudioData.parse(<<144, 120, 120, 120, 120, 1, 2, 3>>)
      {:error, "invalid fourcc: \\"xxxx\\""}

      iex> ExFLV.Tag.ExAudioData.parse(<<80, 97, 99, 45, 51, 1, 2, 3>>)
      {:error, :invalid_data}
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, reason :: any()}
  def parse(
        <<9::4, 4::4, fourcc::binary-size(4), channel_order::8, channel_count::8, data::binary>>
      )
      when channel_order in 0..2 do
    channel_order = parse_channel_order(channel_order)

    with {:ok, fourcc} <- parse_fourcc(fourcc),
         {:ok, channels, rest} <- parse_channels(channel_order, channel_count, data) do
      {:ok,
       %__MODULE__{
         packet_type: :multi_channel_config,
         fourcc: fourcc,
         channel_order: channel_order,
         channel_count: channel_count,
         channels: channels,
         data: rest
       }}
    end
  end

  def parse(<<9::4, packet_type::4, fourcc::binary-size(4), data::binary>>)
      when packet_type in [0, 1, 2, 7] do
    with {:ok, fourcc} <- parse_fourcc(fourcc) do
      {:ok,
       %__MODULE__{
         packet_type: parse_packet_type(packet_type),
         fourcc: fourcc,
         data: data
       }}
    end
  end

  def parse(_), do: {:error, :invalid_data}

  @doc """
  Same as `parse/1` but raises on error.

      iex> ExFLV.Tag.ExAudioData.parse!(<<148, 102, 76, 97, 67, 1, 2, 0, 0, 0, 3>>)
      %ExFLV.Tag.ExAudioData{
        packet_type: :multi_channel_config,
        fourcc: :flac,
        channel_order: :native,
        channel_count: 2,
        channels: [:front_left, :front_right],
        data: <<>>
      }
  """
  @spec parse!(binary()) :: t()
  def parse!(data) do
    case parse(data) do
      {:ok, tag} -> tag
      {:error, reason} -> raise "Failed to parse FLV audio data tag: #{inspect(reason)}"
    end
  end

  defp parse_packet_type(0), do: :sequence_start
  defp parse_packet_type(1), do: :coded_frames
  defp parse_packet_type(2), do: :sequence_end
  # defp parse_packet_type(5), do: :multi_track
  defp parse_packet_type(7), do: :mod_ex

  defp parse_fourcc("ac-3"), do: {:ok, :ac3}
  defp parse_fourcc("ec-3"), do: {:ok, :eac3}
  defp parse_fourcc("Opus"), do: {:ok, :opus}
  defp parse_fourcc(".mp3"), do: {:ok, :mp3}
  defp parse_fourcc("fLaC"), do: {:ok, :flac}
  defp parse_fourcc("mp4a"), do: {:ok, :aac}
  defp parse_fourcc(fourcc), do: {:error, "invalid fourcc: #{inspect(fourcc)}"}

  defp parse_channel_order(0), do: :unspecified
  defp parse_channel_order(1), do: :native
  defp parse_channel_order(2), do: :custom

  defp parse_channels(:unspecified, _count, data), do: {:ok, nil, data}

  defp parse_channels(:native, _count, <<flags::32, data::binary>>) do
    channels =
      Enum.reduce(0..31, [], fn bit, acc ->
        case Bitwise.band(flags, Bitwise.bsl(1, bit)) do
          0 -> acc
          _ -> [Map.get(@audio_channels, bit) | acc]
        end
      end)

    {:ok, Enum.reverse(channels), data}
  end

  defp parse_channels(:custom, count, data) when byte_size(data) >= count do
    <<channels_data::binary-size(count), data::binary>> = data

    channels_data
    |> :binary.bin_to_list()
    |> Enum.reduce_while([], fn byte, acc ->
      case Map.get(@audio_channels, byte) do
        nil -> {:halt, {:error, "invalid channel mapping: #{byte}"}}
        channel -> {:cont, [channel | acc]}
      end
    end)
    |> case do
      {:error, _} = error -> error
      channels -> {:ok, Enum.reverse(channels), data}
    end
  end

  defp parse_channels(_, _count, _data), do: {:error, :invalid_data}
end
