defmodule ExFLV.Header do
  @moduledoc """
  Module describing an FLV header.
  """

  @header_size 9

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          audio?: boolean(),
          video?: boolean()
        }

  defstruct [:version, audio?: false, video?: false]

  @doc """
  Creates a new header struct.
  """
  @spec new(non_neg_integer(), boolean(), boolean()) :: t()
  def new(version, audio?, video?) do
    %__MODULE__{version: version, audio?: audio?, video?: video?}
  end

  @doc """
  Serializes the header struct into a binary.
  """
  @spec serialize(t()) :: binary()
  def serialize(%__MODULE__{version: version, audio?: audio?, video?: video?}) do
    audio_flag = if audio?, do: 1, else: 0
    video_flag = if video?, do: 1, else: 0
    <<"FLV", version::8, 0::5, audio_flag::1, 0::1, video_flag::1, @header_size::32>>
  end
end
