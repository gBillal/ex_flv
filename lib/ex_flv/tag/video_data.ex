defmodule ExFLV.Tag.VideoData do
  @moduledoc """
  Module describing flv VIDEODATA.
  """

  alias ExFLV.Tag.VideoData.AVC

  @type frame_type ::
          :keyframe
          | :interframe
          | :disposable_interframe
          | :generated_keyframe
          | :command_frame

  @type codec_id ::
          :jpeg
          | :sorenson_h263
          | :screen_video
          | :vp6
          | :vp6_alpha
          | :screen_video_v2
          | :avc

  @type t :: %__MODULE__{
          frame_type: frame_type(),
          codec_id: codec_id(),
          data: iodata() | AVC.t()
        }

  defstruct [:frame_type, :codec_id, :data]

  @doc """
  Creates a new `VIDEODATA` tag.
  """
  @spec new(binary(), codec_id(), frame_type()) :: t()
  def new(data, codec_id, frame_type) do
    %__MODULE__{
      frame_type: frame_type,
      codec_id: codec_id,
      data: data
    }
  end

  @doc """
  Parses the binary into a `VIDEODATA` tag.
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, any()}
  def parse(<<0::1, frame_type::3, codec_id::4, data::binary>>) do
    codec = parse_codec_id(codec_id)

    with {:ok, data} <- parse_payload(codec, data) do
      {:ok,
       %__MODULE__{
         frame_type: parse_frame_type(frame_type),
         codec_id: codec,
         data: data
       }}
    end
  end

  @doc """
  Same as `parse/1` but raises on error.

      iex> ExFLV.Tag.VideoData.parse!(<<34, 0, 1, 2, 3>>)
      %ExFLV.Tag.VideoData{
        frame_type: :interframe,
        codec_id: :sorenson_h263,
        data: <<0, 1, 2, 3>>
      }
  """
  @spec parse!(binary()) :: t()
  def parse!(data) do
    case parse(data) do
      {:ok, tag} -> tag
      {:error, reason} -> raise "Failed to parse VideoData tag: #{inspect(reason)}"
    end
  end

  defp parse_frame_type(1), do: :keyframe
  defp parse_frame_type(2), do: :interframe
  defp parse_frame_type(3), do: :disposable_interframe
  defp parse_frame_type(4), do: :generated_keyframe
  defp parse_frame_type(5), do: :command_frame
  defp parse_frame_type(_), do: :unknown

  defp parse_codec_id(1), do: :jpeg
  defp parse_codec_id(2), do: :sorenson_h263
  defp parse_codec_id(3), do: :screen_video
  defp parse_codec_id(4), do: :vp6
  defp parse_codec_id(5), do: :vp6_alpha
  defp parse_codec_id(6), do: :screen_video_v2
  defp parse_codec_id(7), do: :avc
  defp parse_codec_id(_), do: :unknown

  defp parse_payload(:avc, data), do: AVC.parse(data)
  defp parse_payload(_, data), do: {:ok, data}

  defimpl ExFLV.Tag.Serializer do
    alias ExFLV.Tag.Serializer

    def serialize(video_data) do
      [
        <<serialize_frame_type(video_data.frame_type)::4,
          serialize_codec_id(video_data.codec_id)::4>>,
        serialize_data(video_data.data)
      ]
    end

    defp serialize_frame_type(:keyframe), do: 1
    defp serialize_frame_type(:interframe), do: 2
    defp serialize_frame_type(:disposable_interframe), do: 3
    defp serialize_frame_type(:generated_keyframe), do: 4
    defp serialize_frame_type(:command_frame), do: 5

    defp serialize_codec_id(:jpeg), do: 1
    defp serialize_codec_id(:sorenson_h263), do: 2
    defp serialize_codec_id(:screen_video), do: 3
    defp serialize_codec_id(:vp6), do: 4
    defp serialize_codec_id(:vp6_alpha), do: 5
    defp serialize_codec_id(:screen_video_v2), do: 6
    defp serialize_codec_id(:avc), do: 7

    defp serialize_data(%AVC{} = data), do: Serializer.serialize(data)
    defp serialize_data(data), do: data
  end
end
