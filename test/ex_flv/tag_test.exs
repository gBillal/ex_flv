defmodule ExFLV.TagTest do
  use ExUnit.Case, async: true

  doctest ExFLV.Tag.AudioData.AAC

  alias ExFLV.Tag.AudioData.AAC
  alias ExFLV.Tag.{AVCVideoPacket, AudioData, VideoData}

  @audio_data <<0x01, 0x02, 0x03, 0x04, 0x05>>
  @video_data <<0x01, 0x02, 0x03, 0x04, 0x05>>

  test "serialize and parse tag with audio" do
    data =
      @audio_data
      |> AAC.new(:raw)
      |> AudioData.new(:aac, 3, 1, :stereo)

    tag = %ExFLV.Tag{type: :audio, timestamp: 0, data: data}
    serialized = ExFLV.Tag.serialize(tag)

    assert {:ok, %ExFLV.Tag{type: :audio, timestamp: 0, data: ^data}} =
             ExFLV.Tag.parse(IO.iodata_to_binary(serialized))
  end

  test "serialize and parse tag with video" do
    data =
      @video_data
      |> AVCVideoPacket.new(:nalu, 0)
      |> VideoData.new(:avc, :interframe)

    tag = %ExFLV.Tag{type: :video, timestamp: 1_000, data: data}
    serialized = ExFLV.Tag.serialize(tag)

    assert {:ok, %ExFLV.Tag{type: :video, timestamp: 1_000, data: ^data}} =
             ExFLV.Tag.parse(IO.iodata_to_binary(serialized))
  end
end
