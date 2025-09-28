defmodule ExFLV.Tag.AudioData.AAC do
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

      iex> ExFLV.Tag.AudioData.AAC.parse(<<0, 1, 2, 3>>)
      {:ok, %ExFLV.Tag.AudioData.AAC{packet_type: :sequence_header, data: <<1, 2, 3>>}}

      iex> ExFLV.Tag.AudioData.AAC.parse(<<1, 1, 2, 3>>)
      {:ok, %ExFLV.Tag.AudioData.AAC{packet_type: :raw, data: <<1, 2, 3>>}}

      iex> ExFLV.Tag.AudioData.AAC.parse(<<2, 1, 2, 3>>)
      {:error, :invalid_data}
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_data}
  def parse(<<packet_type::8, data::binary>> = _tag) when packet_type in 0..1 do
    {:ok,
     %__MODULE__{
       packet_type: parse_packet_type(packet_type),
       data: data
     }}
  end

  def parse(_), do: {:error, :invalid_data}

  @doc """
  Same as `parse/1` but raises on error.

      iex> ExFLV.Tag.AudioData.AAC.parse!(<<0, 1, 2, 3>>)
      %ExFLV.Tag.AudioData.AAC{packet_type: :sequence_header, data: <<1, 2, 3>>}
  """
  @spec parse!(binary()) :: t()
  def parse!(data) do
    case parse(data) do
      {:ok, tag} -> tag
      {:error, reason} -> raise "Failed to parse AACAUDIODATA: #{inspect(reason)}"
    end
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
