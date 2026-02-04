# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBirdTypesTest do
  use ExUnit.Case

  alias ScratchBird.Types
  alias ScratchBird.Types.{Composite, CompositeField, Cidr, Inet, Macaddr, Range}

  test "array literal round-trip (binary unknown)" do
    {param, _oid} = Types.encode_param([1, 2, 3])
    decoded = Types.decode_value(0, param.data, 1)
    assert decoded == [1, 2, 3]
  end

  test "vector literal round-trip" do
    {param, oid} = Types.encode_param([1.0, 2.5, 3.25])
    assert oid == 16_386
    decoded = Types.decode_value(oid, param.data, 1)
    assert decoded == [1.0, 2.5, 3.25]
  end

  test "range round-trip (int4range)" do
    range = %Range{
      lower: 1,
      upper: 10,
      lower_inclusive: true,
      upper_inclusive: false,
      range_oid: 3904
    }

    {param, oid} = Types.encode_param(range)
    assert oid == 3904
    decoded = Types.decode_value(oid, param.data, 1)
    assert %Range{} = decoded
    assert decoded.lower == 1
    assert decoded.upper == 10
    assert decoded.lower_inclusive
    refute decoded.upper_inclusive
  end

  test "composite round-trip" do
    comp = %Composite{
      fields: [
        %CompositeField{oid: 23, value: 7},
        %CompositeField{oid: 25, value: "hello"}
      ]
    }

    {param, oid} = Types.encode_param(comp)
    assert oid == 2249
    decoded = Types.decode_value(oid, param.data, 1)
    assert %Composite{} = decoded
    assert Enum.at(decoded.fields, 0).value == 7
    assert Enum.at(decoded.fields, 1).value == "hello"
  end

  test "inet/cidr/macaddr round-trip" do
    {inet_param, inet_oid} = Types.encode_param(%Inet{value: "127.0.0.1"})
    {cidr_param, cidr_oid} = Types.encode_param(%Cidr{value: "10.0.0.0/24"})
    {mac_param, mac_oid} = Types.encode_param(%Macaddr{value: "aa:bb:cc:dd:ee:ff"})

    assert Types.decode_value(inet_oid, inet_param.data, 1) == "127.0.0.1"
    assert Types.decode_value(cidr_oid, cidr_param.data, 1) == "10.0.0.0/24"
    assert Types.decode_value(mac_oid, mac_param.data, 1) == "aa:bb:cc:dd:ee:ff"
  end
end
