defmodule ExFLV.Tag.AVCVideoPacket do
  @moduledoc """
  Module describing an `AVCVIDEOPACKET` tag.
  """

  @type packet_type :: :sequence_header | :nalu | :end_of_sequence

  @type t :: %__MODULE__{
          packet_type: packet_type(),
          composition_time: integer(),
          data: iodata()
        }

  defstruct [:packet_type, :composition_time, :data]

  @doc """
  Creates a new `AVCVIDEOPACKET` tag.
  """
  @spec new(iodata(), packet_type(), integer()) :: t()
  def new(data, packet_type, composition_time) do
    %__MODULE__{
      packet_type: packet_type,
      composition_time: composition_time,
      data: data
    }
  end

  @doc """
  Parses the binary into an `AVCVIDEOPACKET` tag.
  """
  @spec parse(binary()) :: t()
  def parse(<<packet_type::8, composition_time::24-signed, data::binary>> = _tag) do
    %__MODULE__{
      packet_type: parse_packet_type(packet_type),
      composition_time: composition_time,
      data: data
    }
  end

  defp parse_packet_type(0), do: :sequence_header
  defp parse_packet_type(1), do: :nalu
  defp parse_packet_type(2), do: :end_of_sequence

  defimpl ExFLV.Tag.Serializer do
    def serialize(%{data: data} = tag) do
      packet_type =
        case tag.packet_type do
          :sequence_header -> 0
          :nalu -> 1
          :end_of_sequence -> 2
        end

      [packet_type, <<tag.composition_time::24-signed>>, data]
    end
  end
end
