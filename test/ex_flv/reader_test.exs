defmodule ExFLV.ReaderTest do
  use ExUnit.Case, async: true

  alias ExFLV.{Reader, Tag}

  describe "new" do
    test "success" do
      assert {:ok, %Reader{audio?: true, video?: true}} = Reader.new("test/fixtures/avc_aac.flv")
      assert %Reader{audio?: true, video?: true} = Reader.new!("test/fixtures/avc_aac.flv")
    end

    test "failure" do
      assert {:error, :enoent} = Reader.new("non_existent.flv")

      assert_raise RuntimeError, ~r/Failed to create FLV reader/, fn ->
        Reader.new!("non_existent.flv")
      end
    end
  end

  describe "Read tags" do
    setup do
      {:ok, reader} = Reader.new("test/fixtures/avc_aac.flv")
      %{reader: reader}
    end

    test "next_tag/1 reads tags correctly", %{reader: reader} do
      assert {:ok, %Tag{type: :script}} = Reader.next_tag(reader)
      assert {:ok, %Tag{type: :video, data: %Tag.VideoData{}}} = Reader.next_tag(reader)
      assert {:ok, %Tag{type: :audio, data: %Tag.AudioData{}}} = Reader.next_tag(reader)

      tags = read_all_tags(reader)
      assert tags != []
      assert Enum.all?(tags, fn tag -> tag.type in [:audio, :video] end)

      assert Enum.all?(tags, fn
               %{type: :audio} = tag -> tag.data.sound_format == :aac
               %{type: :video} = tag -> tag.data.codec_id == :avc
             end)
    end

    defp read_all_tags(reader) do
      case Reader.next_tag(reader) do
        {:ok, tag} -> [tag | read_all_tags(reader)]
        :eof -> []
        {:error, reason} -> flunk("Unexpected error: #{inspect(reason)}")
      end
    end
  end
end
