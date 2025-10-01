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
  Parses the binary into a header struct.

      iex> ExFLV.Header.parse(<<70, 76, 86, 1, 5, 0, 0, 0, 9>>)
      {:ok, %ExFLV.Header{version: 1, audio?: true, video?: true}}

      iex> ExFLV.Header.parse(<<70, 76, 86, 1, 0, 0, 0, 0, 9>>)
      {:ok, %ExFLV.Header{version: 1, audio?: false, video?: false}}

      iex> ExFLV.Header.parse("INVALID")
      {:error, :invalid_header}
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_header}
  def parse(<<"FLV", version::8, 0::5, audio::1, 0::1, video::1, 0x09::32>>) do
    {:ok, %__MODULE__{version: version, audio?: audio == 1, video?: video == 1}}
  end

  def parse(_), do: {:error, :invalid_header}

  @doc """
  Serializes the header struct into a binary.

      iex> ExFLV.Header.serialize(%ExFLV.Header{version: 1, audio?: true, video?: true})
      <<70, 76, 86, 1, 5, 0, 0, 0, 9>>

      iex> ExFLV.Header.serialize(%ExFLV.Header{version: 1, audio?: false, video?: false})
      <<70, 76, 86, 1, 0, 0, 0, 0, 9>>
  """
  @spec serialize(t()) :: binary()
  def serialize(%__MODULE__{version: version, audio?: audio?, video?: video?}) do
    audio_flag = if audio?, do: 1, else: 0
    video_flag = if video?, do: 1, else: 0
    <<"FLV", version::8, 0::5, audio_flag::1, 0::1, video_flag::1, @header_size::32>>
  end
end
