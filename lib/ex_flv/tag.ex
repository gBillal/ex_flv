defmodule ExFLV.Tag do
  @moduledoc """
  Module describing an FLV tag.
  """

  alias __MODULE__.{AudioData, VideoData}

  @type t :: %__MODULE__{
          type: :audio | :video | :script,
          data_size: non_neg_integer(),
          timestamp: non_neg_integer(),
          data: iodata() | AudioData.t() | VideoData.t()
        }

  defstruct [:type, :data_size, :timestamp, :data]

  @spec parse(binary()) :: {t(), binary()} | :more
  def parse(
        <<type::8, data_size::24, timestamp::24, timestamp_extended::8, _stream_id::24,
          data::binary-size(data_size), rest::binary>>
      ) do
    <<timestamp::signed-32>> = <<timestamp_extended::8, timestamp::24>>

    tag = %__MODULE__{
      type: parse_type(type),
      data_size: data_size,
      timestamp: timestamp,
      data: parse_payload(type, data)
    }

    {tag, rest}
  end

  def parse(_data), do: :more

  @spec serialize(t()) :: iodata()
  def serialize(tag) do
    <<extended_timestamp::signed-8, timestamp::binary>> = <<tag.timestamp::signed-32>>

    payload = if is_struct(tag.data), do: ExFLV.Tag.Serializer.serialize(tag.data), else: tag.data

    [
      serialize_type(tag.type),
      <<IO.iodata_length(payload)::24>>,
      timestamp,
      extended_timestamp,
      <<0::24>>,
      payload
    ]
  end

  defp parse_type(8), do: :audio
  defp parse_type(9), do: :video
  defp parse_type(18), do: :script

  defp parse_payload(8, data), do: AudioData.parse(data)
  defp parse_payload(9, data), do: VideoData.parse(data)
  defp parse_payload(_type, data), do: data

  defp serialize_type(:audio), do: 8
  defp serialize_type(:video), do: 9
  defp serialize_type(:script), do: 18
end
