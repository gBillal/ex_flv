defmodule ExFLV.Tag do
  @moduledoc """
  Module describing an FLV tag.
  """

  alias __MODULE__.{AudioData, ExAudioData, ExVideoData, Serializer, VideoData}

  @type t :: %__MODULE__{
          type: :audio | :video | :script,
          timestamp: non_neg_integer(),
          data: iodata() | AudioData.t() | VideoData.t() | ExVideoData.t() | nil
        }

  defstruct [:type, :timestamp, :data]

  @doc """
  Parses the binary into an flv tag.
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, any()} | :more
  def parse(
        <<type::8, data_size::24, timestamp::24, timestamp_extended::8, _stream_id::24,
          data::binary-size(data_size)>>
      ) do
    <<timestamp::signed-32>> = <<timestamp_extended::8, timestamp::24>>

    with {:ok, type} <- parse_type(type),
         {:ok, payload} <- parse_payload(type, data) do
      {:ok, %__MODULE__{type: type, timestamp: timestamp, data: payload}}
    end
  end

  def parse(_data), do: :more

  @doc """
  Same as `parse/1` but raises on error or insufficient data.
  """
  @spec parse!(binary()) :: t()
  def parse!(data) do
    case parse(data) do
      {:ok, tag} -> tag
      {:error, reason} -> raise "Failed to parse FLV tag: #{inspect(reason)}"
      :more -> raise "Insufficient data to parse FLV tag"
    end
  end

  @doc """
  Serializes the flv tag.
  """
  @spec serialize(t()) :: iodata()
  def serialize(tag) do
    <<extended_timestamp::signed-8, timestamp::binary>> = <<tag.timestamp::signed-32>>
    payload = if is_struct(tag.data), do: Serializer.serialize(tag.data), else: tag.data

    [
      serialize_type(tag.type),
      <<IO.iodata_length(payload)::24>>,
      timestamp,
      extended_timestamp,
      <<0::24>>,
      payload
    ]
  end

  defp parse_type(8), do: {:ok, :audio}
  defp parse_type(9), do: {:ok, :video}
  defp parse_type(18), do: {:ok, :script}
  defp parse_type(_), do: {:error, :unknown_type}

  defp parse_payload(:audio, <<9::4, _rest::bitstring>> = data), do: ExAudioData.parse(data)
  defp parse_payload(:audio, data), do: AudioData.parse(data)
  defp parse_payload(:video, <<0::1, _rest::bitstring>> = data), do: VideoData.parse(data)
  defp parse_payload(:video, data), do: ExVideoData.parse(data)
  defp parse_payload(:script, data), do: {:ok, data}

  defp serialize_type(:audio), do: 8
  defp serialize_type(:video), do: 9
  defp serialize_type(:script), do: 18
end
