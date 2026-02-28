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
