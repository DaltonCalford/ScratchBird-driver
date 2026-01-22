require "test_helper"

class TestTypes < Minitest::Test
  def test_decode_uuid
    bytes = ["12345678123456781234567812345678"].pack("H*")
    out = Scratchbird::Types.decode(Scratchbird::Types::WIRE_UUID, bytes)
    assert_equal "12345678-1234-5678-1234-567812345678", out
  end

  def test_decode_array
    data = "{1,2,3}".dup.force_encoding("UTF-8")
    out = Scratchbird::Types.decode(Scratchbird::Types::WIRE_ARRAY, data)
    assert_equal [1, 2, 3], out
  end
end
