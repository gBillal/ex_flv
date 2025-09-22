defprotocol ExFLV.Tag.Serializer do
  @moduledoc """
  Protocol to serialize FLV tags.
  """

  def serialize(tag)
end
