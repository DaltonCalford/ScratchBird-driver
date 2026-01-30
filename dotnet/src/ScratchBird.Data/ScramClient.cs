// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Security.Cryptography;
using System.Text;

namespace ScratchBird.Data;

internal sealed class ScramClient
{
    private readonly string _username;
    private readonly string _nonce;
    private string _clientFirstBare = string.Empty;
    private byte[]? _serverSignature;

    public ScramClient(string username, string? nonce = null)
    {
        _username = username ?? string.Empty;
        _nonce = nonce ?? Convert.ToBase64String(RandomNumberGenerator.GetBytes(18));
    }

    public string ClientFirstMessage()
    {
        _clientFirstBare = $"n={Escape(_username)},r={_nonce}";
        return $"n,,{_clientFirstBare}";
    }

    public string HandleServerFirst(string password, string serverFirst)
    {
        var attrs = ParseAttributes(serverFirst);
        if (!attrs.TryGetValue("r", out var nonce) || !nonce.StartsWith(_nonce, StringComparison.Ordinal))
        {
            throw new InvalidOperationException("SCRAM server nonce mismatch");
        }
        if (!attrs.TryGetValue("s", out var saltB64) || !attrs.TryGetValue("i", out var iterStr))
        {
            throw new InvalidOperationException("SCRAM server-first missing fields");
        }

        var iterations = int.Parse(iterStr);
        var salt = Convert.FromBase64String(saltB64);
        var saltedPassword = Hi(password ?? string.Empty, salt, iterations);
        var clientKey = Hmac(saltedPassword, "Client Key");
        var storedKey = SHA256.HashData(clientKey);
        var clientFinalWithoutProof = $"c=biws,r={nonce}";
        var authMessage = $"{_clientFirstBare},{serverFirst},{clientFinalWithoutProof}";
        var clientSignature = Hmac(storedKey, authMessage);
        var clientProof = Xor(clientKey, clientSignature);
        var serverKey = Hmac(saltedPassword, "Server Key");
        _serverSignature = Hmac(serverKey, authMessage);
        return $"{clientFinalWithoutProof},p={Convert.ToBase64String(clientProof)}";
    }

    public void VerifyServerFinal(string serverFinal)
    {
        var attrs = ParseAttributes(serverFinal);
        if (!attrs.TryGetValue("v", out var verifier) || _serverSignature == null)
        {
            throw new InvalidOperationException("SCRAM server-final missing verifier");
        }
        var expected = Convert.ToBase64String(_serverSignature);
        if (!string.Equals(verifier, expected, StringComparison.Ordinal))
        {
            throw new InvalidOperationException("SCRAM server signature mismatch");
        }
    }

    private static string Escape(string value)
    {
        return value.Replace("=", "=3D", StringComparison.Ordinal).Replace(",", "=2C", StringComparison.Ordinal);
    }

    private static Dictionary<string, string> ParseAttributes(string message)
    {
        var dict = new Dictionary<string, string>(StringComparer.Ordinal);
        if (string.IsNullOrEmpty(message)) return dict;
        var parts = message.Split(',');
        foreach (var part in parts)
        {
            var idx = part.IndexOf('=');
            if (idx > 0)
            {
                dict[part[..idx]] = part[(idx + 1)..];
            }
        }
        return dict;
    }

    private static byte[] Hi(string password, byte[] salt, int iterations)
    {
        using var derive = new Rfc2898DeriveBytes(password, salt, iterations, HashAlgorithmName.SHA256);
        return derive.GetBytes(32);
    }

    private static byte[] Hmac(byte[] key, string data)
    {
        using var hmac = new HMACSHA256(key);
        return hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
    }

    private static byte[] Xor(byte[] left, byte[] right)
    {
        var output = new byte[left.Length];
        for (var i = 0; i < left.Length; i++)
        {
            output[i] = (byte)(left[i] ^ right[i]);
        }
        return output;
    }
}
