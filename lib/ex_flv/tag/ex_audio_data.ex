defmodule ExFLV.Tag.ExAudioData do
  @moduledoc """
  Module describing an enhanced audio data tag.
  """

  @type packet_type ::
          :sequence_start
          | :coded_frames
          | :sequence_end
          | :multi_channel_config
          | :multi_track
          | :mod_ex
  @type fourcc :: :ac3 | :eac3 | :opus | :mp3 | :flac | :aac
  @type channel_order :: :unspecified | :native | :custom

  @type t :: %__MODULE__{
          packet_type: packet_type(),
          fourcc: fourcc(),
          channel_order: channel_order() | nil,
          channel_count: non_neg_integer() | nil,
          channel_mapping: non_neg_integer() | list(non_neg_integer()) | nil,
          data: iodata()
        }

  defstruct [:packet_type, :fourcc, :channel_order, :channel_count, :channel_mapping, :data]

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
         channel_mapping: 3,
         data: <<>>
       }}

      iex> ExFLV.Tag.ExAudioData.parse(<<145, 109, 112, 52, 97, 255, 248, 89, 174, 0, 90, 78, 0>>)
      {:ok,
       %ExFLV.Tag.ExAudioData{
         packet_type: :coded_frames,
         fourcc: :aac,
         channel_order: nil,
         channel_count: nil,
         channel_mapping: nil,
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
         {:ok, mapping, rest} <- parse_channel_mapping(channel_order, channel_count, data) do
      {:ok,
       %__MODULE__{
         packet_type: :multi_channel_config,
         fourcc: fourcc,
         channel_order: channel_order,
         channel_count: channel_count,
         channel_mapping: mapping,
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
        channel_mapping: 3,
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

  defp parse_channel_mapping(:unspecified, _count, data), do: {:ok, nil, data}
  defp parse_channel_mapping(:native, _count, <<flags::32, data::binary>>), do: {:ok, flags, data}

  defp parse_channel_mapping(:custom, count, data) when byte_size(data) >= count do
    mapping = :binary.part(data, 0, count) |> :binary.bin_to_list()
    {:ok, mapping, data}
  end

  defp parse_channel_mapping(_, _count, _data), do: {:error, :invalid_data}
end
