defmodule ExFLV.Tag.AudioData do
  @moduledoc """
  Module describing flv AUDIODATA.
  """

  alias ExFLV.Tag.AACAudioData

  @type sound_format ::
          :pcm
          | :adpcm
          | :mp3
          | :pcm_le
          | :nellymoser_16khz_mono
          | :nellymoser_8khz_mono
          | :nellymoser
          | :g711_alaw
          | :g711_mulaw
          | :reserved
          | :aac
          | :speex
          | :mp3_8khz
          | :device_specific

  @type sound_type :: :mono | :stereo

  @type t :: %__MODULE__{
          sound_format: sound_format(),
          sound_rate: non_neg_integer(),
          sound_size: non_neg_integer(),
          sound_type: sound_type(),
          data: binary()
        }

  defstruct [:sound_format, :sound_rate, :sound_size, :sound_type, :data]

  @sound_format_map %{
    0 => :pcm,
    1 => :adpcm,
    2 => :mp3,
    3 => :pcm_le,
    4 => :nellymoser_16khz_mono,
    5 => :nellymoser_8khz_mono,
    6 => :nellymoser,
    7 => :g711_alaw,
    8 => :g711_mulaw,
    9 => :reserved,
    10 => :aac,
    11 => :speex,
    14 => :mp3_8khz,
    15 => :device_specific
  }

  @doc """
  Creates a new `AUDIODATA` tag.
  """
  @spec new(iodata(), sound_format(), non_neg_integer(), non_neg_integer(), sound_type()) ::
          t()
  def new(data, sound_format, sound_rate, sound_size, sound_type) do
    %__MODULE__{
      sound_format: sound_format,
      sound_rate: sound_rate,
      sound_size: sound_size,
      sound_type: sound_type,
      data: data
    }
  end

  @spec parse(binary()) :: t()
  def parse(<<sound_format::4, sound_rate::2, sound_size::1, sound_type::1, data::binary>>) do
    format = Map.fetch!(@sound_format_map, sound_format)

    data =
      case format do
        :aac -> AACAudioData.parse(data)
        _ -> data
      end

    %__MODULE__{
      sound_format: format,
      sound_rate: sound_rate,
      sound_size: sound_size,
      sound_type: parse_sound_type(sound_type),
      data: data
    }
  end

  defp parse_sound_type(0), do: :mono
  defp parse_sound_type(1), do: :stereo

  defimpl ExFLV.Tag.Serializer do
    alias ExFLV.Tag.Serializer

    @sound_format_map_rev Map.new(
                            Module.get_attribute(ExFLV.Tag.AudioData, :sound_format_map),
                            fn {k, v} -> {v, k} end
                          )

    def serialize(audio_data) do
      sound_format = @sound_format_map_rev[audio_data.sound_format]

      [
        <<sound_format::4, audio_data.sound_rate::2, audio_data.sound_size::1,
          serialize_sound_type(audio_data.sound_type)::1>>,
        serialize_data(audio_data.data)
      ]
    end

    defp serialize_data(%AACAudioData{} = aac_data), do: Serializer.serialize(aac_data)
    defp serialize_data(data), do: data

    defp serialize_sound_type(:mono), do: 0
    defp serialize_sound_type(:stereo), do: 1
  end
end
