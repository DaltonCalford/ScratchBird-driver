# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
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
