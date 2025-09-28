defmodule ExFLV.Tag.ExVideoDataTest do
  use ExUnit.Case, async: true

  alias ExFLV.Tag.ExVideoData

  doctest ExFLV.Tag.ExVideoData

  describe "parse!/1" do
    test "raises for invalid binary" do
      assert_raise RuntimeError, "Failed to parse EXVIDEODATA: invalid_tag", fn ->
        ExVideoData.parse!(<<150, 97, 118, 48>>)
      end
    end
  end
end
