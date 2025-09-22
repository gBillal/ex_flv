defmodule ExFLV.Tag.AACAudioData do
  @moduledoc """
  Module describing an `AACAUDIODATA` tag.
  """

  @type packet_type :: :sequence_header | :raw

  @type t :: %__MODULE__{
          packet_type: packet_type(),
          data: iodata()
        }

  defstruct [:packet_type, :data]

  @doc """
  Creates a new `AACAUDIODATA`.
  """
  @spec new(iodata(), packet_type()) :: t()
  def new(data, packet_type) do
    %__MODULE__{
      packet_type: packet_type,
      data: data
    }
  end

  @doc """
  Parses the binary into an `AACAUDIODATA` tag.
  """
  @spec parse(binary()) :: t()
  def parse(<<packet_type::8, data::binary>> = _tag) do
    %__MODULE__{
      packet_type: parse_packet_type(packet_type),
      data: data
    }
  end

  defp parse_packet_type(0), do: :sequence_header
  defp parse_packet_type(1), do: :raw

  defimpl ExFLV.Tag.Serializer do
    def serialize(aac_data) do
      [serialize_packet_type(aac_data.packet_type), aac_data.data]
    end

    defp serialize_packet_type(:sequence_header), do: 0
    defp serialize_packet_type(:raw), do: 1
  end
end
