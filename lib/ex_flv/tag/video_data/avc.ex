defmodule ExFLV.Tag.VideoData.AVC do
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

  ## Examples

      iex> ExFLV.Tag.VideoData.AVC.new(<<1, 2, 3>>, :nalu, 0)
      %ExFLV.Tag.VideoData.AVC{
        packet_type: :nalu,
        composition_time: 0,
        data: <<1, 2, 3>>
      }
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

      iex> ExFLV.Tag.VideoData.AVC.parse(<<1, 0, 0, 0, 1, 2, 3>>)
      {:ok,
       %ExFLV.Tag.VideoData.AVC{
         packet_type: :nalu,
         composition_time: 0,
         data: <<1, 2, 3>>
       }}

      iex> ExFLV.Tag.VideoData.AVC.parse(<<0, 0, 0, 0, 4, 5, 6>>)
      {:ok,
       %ExFLV.Tag.VideoData.AVC{
         packet_type: :sequence_header,
         composition_time: 0,
         data: <<4, 5, 6>>
       }}

      iex> ExFLV.Tag.VideoData.AVC.parse(<<2, 255, 255, 255>>)
      {:ok,
       %ExFLV.Tag.VideoData.AVC{
         packet_type: :end_of_sequence,
         composition_time: -1,
         data: ""
       }}

      iex> ExFLV.Tag.VideoData.AVC.parse(<<3, 0, 0, 0, 7, 8, 9>>)
      {:error, :invalid_data}
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_data}
  def parse(<<packet_type::8, composition_time::24-signed, data::binary>> = _tag)
      when packet_type in 0..2 do
    {:ok,
     %__MODULE__{
       packet_type: parse_packet_type(packet_type),
       composition_time: composition_time,
       data: data
     }}
  end

  def parse(_), do: {:error, :invalid_data}

  @doc """
  Same as `parse/1` but raises on error.

      iex> ExFLV.Tag.VideoData.AVC.parse!(<<1, 0, 0, 0, 1, 2, 3>>)
      %ExFLV.Tag.VideoData.AVC{
        packet_type: :nalu,
        composition_time: 0,
        data: <<1, 2, 3>>
      }
  """
  @spec parse!(binary()) :: t()
  def parse!(data) do
    case parse(data) do
      {:ok, tag} -> tag
      {:error, reason} -> raise "Failed to parse AVC video packet: #{inspect(reason)}"
    end
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
