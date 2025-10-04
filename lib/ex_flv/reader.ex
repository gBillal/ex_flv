defmodule ExFLV.Reader do
  @moduledoc """
  Module for reading FLV files.
  """

  alias ExFLV.{Header, Tag}

  @header_size 9
  @tag_header_size 11

  @type t :: %__MODULE__{
          file: File.io_device(),
          audio?: boolean(),
          video?: boolean()
        }

  defstruct [:file, :audio?, :video?]

  @doc """
  Creates a new reader.
  """
  @spec new(Path.t()) :: {:ok, t()} | {:error, any()}
  def new(path) do
    with {:ok, file} <- File.open(path, [:binary, :read]),
         {:ok, header} <- Header.parse(IO.binread(file, @header_size)),
         <<0::32>> <- IO.binread(file, 4) do
      {:ok, %__MODULE__{file: file, audio?: header.audio?, video?: header.video?}}
    end
  end

  @doc """
  Same as `new/1`, but raises in case of failure.
  """
  @spec new!(Path.t()) :: t()
  def new!(path) do
    case new(path) do
      {:ok, reader} -> reader
      {:error, reason} -> raise "Failed to create FLV reader: #{inspect(reason)}"
    end
  end

  @doc """
  Reads the next tag from the FLV file.
  """
  @spec next_tag(t()) :: {:ok, Tag.t()} | {:error, any()} | :eof
  def next_tag(%{file: file}) do
    with {:ok, body_size, header} <- read_tag_header(file),
         {:ok, body_data} <- read_tag_data(file, body_size) do
      Tag.parse(header <> body_data)
    end
  end

  @doc """
  Same as `next_tag/1`, but raises in case of failure.
  """
  @spec next_tag!(t()) :: Tag.t() | :eof
  def next_tag!(reader) do
    case next_tag(reader) do
      {:ok, tag} -> tag
      :eof -> :eof
      {:error, reason} -> raise "Failed to read next FLV tag: #{inspect(reason)}"
    end
  end

  @doc """
  Closes the FLV file.
  """
  @spec close(t()) :: :ok | {:error, any()}
  def close(%{file: file}) do
    File.close(file)
  end

  defp read_tag_header(file) do
    case IO.binread(file, @tag_header_size) do
      <<_type::8, size::24, _rest::binary>> = header -> {:ok, size, header}
      other when is_binary(other) -> {:error, :incomplete_tag_header}
      other -> other
    end
  end

  defp read_tag_data(file, data_size) do
    prev_tag_size = data_size + @tag_header_size

    case IO.binread(file, data_size + 4) do
      <<data::binary-size(data_size), ^prev_tag_size::32>> -> {:ok, data}
      other when is_binary(other) -> {:error, :incomplete_tag_data}
      other -> other
    end
  end
end
