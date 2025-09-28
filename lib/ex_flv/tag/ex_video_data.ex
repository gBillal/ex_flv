defmodule ExFLV.Tag.ExVideoData do
  @moduledoc """
  Module describing an FLV enhanced video data tag.
  """

  alias ExFLV.Tag.VideoData

  @type packet_type ::
          :sequence_start
          | :coded_frames
          | :sequence_end
          | :coded_frames_x
          | :metadata
          | :mpeg2_ts_sequence_start
          | :multi_track
          | :mod_ex

  @type fourcc :: :avc1 | :hvc1 | :vp08 | :vp09 | :av01

  @type t :: %__MODULE__{
          frame_type: VideoData.frame_type(),
          packet_type: packet_type(),
          composition_time_offset: integer(),
          fourcc: fourcc(),
          data: iodata()
        }

  defstruct [:frame_type, :packet_type, :fourcc, :composition_time_offset, :data]

  @frame_types %{
    1 => :keyframe,
    2 => :interframe,
    3 => :disposable_interframe,
    4 => :generated_keyframe,
    5 => :command_frame
  }

  @packet_types %{
    0 => :sequence_start,
    1 => :coded_frames,
    2 => :sequence_end,
    3 => :coded_frames_x,
    4 => :metadata,
    5 => :mpeg2_ts_sequence_start,
    6 => :multi_track,
    7 => :mod_ex
  }

  @doc """
  Parses the binary into an `ExVideoTag` tag.

      iex> ExFLV.Tag.ExVideoData.parse(<<144, 104, 118, 99, 49, 1, 2, 3, 4, 5>>)
      {:ok,
      %ExFLV.Tag.ExVideoData{
        frame_type: :keyframe,
        packet_type: :sequence_start,
        fourcc: :hvc1,
        composition_time_offset: 0,
        data: <<1, 2, 3, 4, 5>>
      }}

      iex> ExFLV.Tag.ExVideoData.parse(<<161, 97, 118, 99, 49, 255, 255, 246, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255>>)
      {:ok,
      %ExFLV.Tag.ExVideoData{
        frame_type: :interframe,
        packet_type: :coded_frames,
        fourcc: :avc1,
        composition_time_offset: -10,
        data: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 255>>
      }}

      iex> ExFLV.Tag.ExVideoData.parse(<<163, 97, 118, 99, 49, 1, 2, 3, 4>>)
      {:ok,
      %ExFLV.Tag.ExVideoData{
        frame_type: :interframe,
        packet_type: :coded_frames_x,
        fourcc: :avc1,
        composition_time_offset: 0,
        data: <<1, 2, 3, 4>>
      }}

      iex> ExFLV.Tag.ExVideoData.parse(<<150, 97, 118, 48>>)
      {:error, :invalid_tag}

      iex> ExFLV.Tag.ExVideoData.parse(<<150, 97, 118, 48, 49>>)
      {:error, :invalid_tag}
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_tag}
  def parse(<<1::1, frame_type::3, packet_type::4, fourcc::binary-size(4), data::binary>>)
      when frame_type in 1..5 and packet_type in 0..7 and packet_type != 6 do
    packet_type = @packet_types[packet_type]
    fourcc = String.to_existing_atom(fourcc)
    {composition_time_offset, data} = parse_body(packet_type, fourcc, data)

    {:ok,
     %__MODULE__{
       frame_type: @frame_types[frame_type],
       fourcc: fourcc,
       composition_time_offset: composition_time_offset,
       packet_type: packet_type,
       data: data
     }}
  end

  def parse(_), do: {:error, :invalid_tag}

  @doc """
  Same as `parse/1` but raises on error.

      iex> ExFLV.Tag.ExVideoData.parse!(<<144, 104, 118, 99, 49, 1, 2, 3, 4, 5>>)
      %ExFLV.Tag.ExVideoData{
        frame_type: :keyframe,
        packet_type: :sequence_start,
        fourcc: :hvc1,
        composition_time_offset: 0,
        data: <<1, 2, 3, 4, 5>>
      }
  """
  @spec parse!(binary()) :: t()
  def parse!(data) do
    case parse(data) do
      {:ok, tag} -> tag
      {:error, reason} -> raise "Failed to parse EXVIDEODATA: #{reason}"
    end
  end

  defp parse_body(:coded_frames, fourcc, <<composition_time_offset::24-signed, data::binary>>)
       when fourcc in [:avc1, :hvc1],
       do: {composition_time_offset, data}

  defp parse_body(_packet_type, _fourcc, data), do: {0, data}
end
