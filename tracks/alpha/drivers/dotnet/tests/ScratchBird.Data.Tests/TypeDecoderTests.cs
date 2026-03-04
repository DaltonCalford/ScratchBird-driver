// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System;
using System.Buffers.Binary;
using System.Text;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class TypeDecoderTests
{
    [Fact]
    public void EncodeParam_JsonObject_UsesJsonOid()
    {
        var encoded = TypeDecoder.EncodeParam(new { role = "admin", active = true });

        Assert.Equal(TypeDecoder.OidJson, encoded.Oid);
        Assert.NotNull(encoded.Param.Data);
        var raw = Encoding.UTF8.GetString(encoded.Param.Data!, 4, encoded.Param.Data!.Length - 4);
        Assert.Contains("\"role\":\"admin\"", raw);
    }

    [Fact]
    public void EncodeParam_RejectsJsonbWithoutPayload()
    {
        var ex = Assert.Throws<InvalidOperationException>(() =>
            TypeDecoder.EncodeParam(new ScratchBirdJsonb(Array.Empty<byte>())));
        Assert.Contains("JSONB requires raw payload", ex.Message);
    }

    [Fact]
    public void DecodeUuidBinary_StripsLengthPrefix()
    {
        var guid = Guid.Parse("11111111-2222-3333-4444-555555555555");
        var encoded = WithLengthPrefix(GuidToDriverBytes(guid));

        var decoded = TypeDecoder.Decode(TypeDecoder.OidUuid, encoded, (byte)TypeDecoder.FormatBinary);

        Assert.Equal(guid, Assert.IsType<Guid>(decoded));
    }

    [Fact]
    public void DecodeUuidBinary_AcceptsDirectBinaryPayload()
    {
        var guid = Guid.Parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");
        var encoded = GuidToDriverBytes(guid);

        var decoded = TypeDecoder.Decode(TypeDecoder.OidUuid, encoded, (byte)TypeDecoder.FormatBinary);

        Assert.Equal(guid, Assert.IsType<Guid>(decoded));
    }

    [Fact]
    public void DecodeUuidBinary_AcceptsLengthPrefixedTextPayload()
    {
        var guid = Guid.Parse("12345678-9abc-def0-1234-56789abcdef0");
        var encoded = WithLengthPrefix(Encoding.UTF8.GetBytes(guid.ToString()));

        var decoded = TypeDecoder.Decode(TypeDecoder.OidUuid, encoded, (byte)TypeDecoder.FormatBinary);

        Assert.Equal(guid, Assert.IsType<Guid>(decoded));
    }

    [Fact]
    public void DecodeBooleanBinary_AcceptsLengthPrefixedPayload()
    {
        var encoded = WithLengthPrefix(new byte[] { 1 });
        var decoded = TypeDecoder.Decode(TypeDecoder.OidBool, encoded, (byte)TypeDecoder.FormatBinary);
        Assert.True(Assert.IsType<bool>(decoded));
    }

    [Fact]
    public void DecodeInt4Binary_AcceptsLengthPrefixedPayload()
    {
        var payload = new byte[4];
        BinaryPrimitives.WriteInt32LittleEndian(payload, 1234);
        var encoded = WithLengthPrefix(payload);

        var decoded = TypeDecoder.Decode(TypeDecoder.OidInt4, encoded, (byte)TypeDecoder.FormatBinary);
        Assert.Equal(1234, Assert.IsType<int>(decoded));
    }

    [Fact]
    public void DecodeVectorBinary_ReturnsFloatArray()
    {
        var encoded = WithLengthPrefix(Encoding.UTF8.GetBytes("[1.5,2,3.25]"));
        var decoded = TypeDecoder.Decode(TypeDecoder.OidSbVector, encoded, (byte)TypeDecoder.FormatBinary);
        var vector = Assert.IsType<float[]>(decoded);
        Assert.Equal(new[] { 1.5f, 2.0f, 3.25f }, vector);
    }

    [Fact]
    public void DecodeMoneyBinary_ReturnsDecimal()
    {
        var encoded = new byte[8];
        BinaryPrimitives.WriteInt64LittleEndian(encoded, 12345);

        var decoded = TypeDecoder.Decode(TypeDecoder.OidMoney, encoded, (byte)TypeDecoder.FormatBinary);

        Assert.Equal(123.45m, Assert.IsType<decimal>(decoded));
    }

    [Fact]
    public void DecodeJsonbBinary_ReturnsScratchBirdJsonb()
    {
        var encoded = WithLengthPrefix(Encoding.UTF8.GetBytes("{\"k\":1}"));

        var decoded = TypeDecoder.Decode(TypeDecoder.OidJsonb, encoded, (byte)TypeDecoder.FormatBinary);
        var jsonb = Assert.IsType<ScratchBirdJsonb>(decoded);

        Assert.Equal("{\"k\":1}", Encoding.UTF8.GetString(jsonb.Raw));
    }

    [Fact]
    public void DecodeInt8RangeBinary_ReturnsExpectedBounds()
    {
        var encoded = new byte[4 + 4 + 8 + 4 + 8];
        BinaryPrimitives.WriteInt32LittleEndian(encoded.AsSpan(4, 4), 8);
        BinaryPrimitives.WriteInt64LittleEndian(encoded.AsSpan(8, 8), 10);
        BinaryPrimitives.WriteInt32LittleEndian(encoded.AsSpan(16, 4), 8);
        BinaryPrimitives.WriteInt64LittleEndian(encoded.AsSpan(20, 8), 20);

        var decoded = TypeDecoder.Decode(TypeDecoder.OidInt8Range, encoded, (byte)TypeDecoder.FormatBinary);
        var range = Assert.IsType<ScratchBirdRange<long>>(decoded);

        Assert.False(range.Empty);
        Assert.Equal(10, range.Lower);
        Assert.Equal(20, range.Upper);
    }

    [Fact]
    public void DecodeCompositeBinary_ReturnsFields()
    {
        var composite = new ScratchBirdComposite(
            new[] { new ScratchBirdCompositeField(TypeDecoder.OidInt4, 77) }
        );
        var encoded = TypeDecoder.EncodeParam(composite);

        Assert.Equal(TypeDecoder.OidRecord, encoded.Oid);
        var decoded = TypeDecoder.Decode(TypeDecoder.OidRecord, encoded.Param.Data, (byte)TypeDecoder.FormatBinary);
        var value = Assert.IsType<ScratchBirdComposite>(decoded);

        var field = Assert.Single(value.Fields);
        Assert.Equal(TypeDecoder.OidInt4, field.Oid);
        Assert.Equal(77, Assert.IsType<int>(field.Value));
    }

    [Fact]
    public void DecodeUnknownValues_UsesTextHeuristics()
    {
        var boolText = TypeDecoder.Decode(0, Encoding.UTF8.GetBytes("true"), (byte)TypeDecoder.FormatText);
        Assert.True(Assert.IsType<bool>(boolText));

        var intText = TypeDecoder.Decode(0, Encoding.UTF8.GetBytes("42"), (byte)TypeDecoder.FormatText);
        Assert.Equal(42, Assert.IsType<int>(intText));

        var binaryTrimmedText = TypeDecoder.Decode(0, new byte[] { (byte)'4', (byte)'2', 0 }, (byte)TypeDecoder.FormatBinary);
        Assert.Equal(42, Assert.IsType<int>(binaryTrimmedText));
    }

    [Fact]
    public void OidAndClrTypeMappings_ResolveKnownAndUnknownTypes()
    {
        Assert.Equal("vector", TypeDecoder.OidToString(TypeDecoder.OidSbVector));
        Assert.Equal("unknown", TypeDecoder.OidToString(999999));

        Assert.Equal(typeof(ScratchBirdRange<long>), TypeDecoder.GetClrType(TypeDecoder.OidInt8Range));
        Assert.Equal(typeof(object), TypeDecoder.GetClrType(999999));
    }

    private static byte[] GuidToDriverBytes(Guid guid)
    {
        var text = guid.ToString("N");
        var buffer = new byte[16];
        for (var i = 0; i < 16; i++)
        {
            buffer[i] = Convert.ToByte(text.Substring(i * 2, 2), 16);
        }
        return buffer;
    }

    private static byte[] WithLengthPrefix(byte[] payload)
    {
        var data = new byte[4 + payload.Length];
        BinaryPrimitives.WriteUInt32LittleEndian(data.AsSpan(0, 4), (uint)payload.Length);
        payload.CopyTo(data, 4);
        return data;
    }
}
