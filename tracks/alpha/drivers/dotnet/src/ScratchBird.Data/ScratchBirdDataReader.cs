// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Collections;
using System.Data;
using System.Data.Common;

namespace ScratchBird.Data;

public sealed class ScratchBirdDataReader : DbDataReader
{
    private readonly ProtocolClient.QueryStream _stream;
    private readonly CommandBehavior _behavior;
    private readonly ScratchBirdConnection? _connection;
    private object?[]? _currentRow;
    private bool _closed;
    private bool _done;
    private bool _prefetched;
    private int _recordsAffected;

    internal ScratchBirdDataReader(ProtocolClient.QueryStream stream, CommandBehavior behavior, ScratchBirdConnection? connection)
    {
        _stream = stream;
        _behavior = behavior;
        _connection = connection;
        _recordsAffected = -1;
    }

    public override object this[int ordinal] => GetValue(ordinal);
    public override object this[string name] => GetValue(GetOrdinal(name));

    public override int Depth => 0;
    public override bool IsClosed => _closed;
    public override int RecordsAffected => _recordsAffected;
    public override int FieldCount => _stream.Columns.Count;

    public override bool HasRows
    {
        get
        {
            if (_currentRow != null)
            {
                return true;
            }
            var row = _stream.ReadNextRow();
            if (row != null)
            {
                _currentRow = row;
                _prefetched = true;
                return true;
            }
            _done = true;
            _recordsAffected = (int)_stream.RowsAffected;
            return false;
        }
    }

    public override bool Read()
    {
        if (_closed)
        {
            return false;
        }
        if (_done)
        {
            return false;
        }
        if (_prefetched)
        {
            _prefetched = false;
            return true;
        }
        _currentRow = null;
        var row = _stream.ReadNextRow();
        if (row == null)
        {
            _done = true;
            _recordsAffected = (int)_stream.RowsAffected;
            return false;
        }
        _currentRow = row;
        return true;
    }

    public override async Task<bool> ReadAsync(CancellationToken cancellationToken)
    {
        using var registration = cancellationToken.Register(() => _connection?.GetConnectedClient().Cancel());
        try
        {
            return await Task.Run(Read, cancellationToken);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                throw new OperationCanceledException(cancellationToken);
            }
            throw;
        }
    }

    public override bool NextResult()
    {
        return false;
    }

    public override Task<bool> NextResultAsync(CancellationToken cancellationToken)
    {
        return Task.FromResult(false);
    }

    public override string GetName(int ordinal)
    {
        return _stream.Columns[ordinal].Name;
    }

    public override int GetOrdinal(string name)
    {
        for (var i = 0; i < _stream.Columns.Count; i++)
        {
            if (string.Equals(_stream.Columns[i].Name, name, StringComparison.OrdinalIgnoreCase))
            {
                return i;
            }
        }
        return -1;
    }

    public override string GetDataTypeName(int ordinal)
    {
        return TypeDecoder.OidToString(_stream.Columns[ordinal].TypeOid);
    }

    public override Type GetFieldType(int ordinal)
    {
        return TypeDecoder.GetClrType(_stream.Columns[ordinal].TypeOid);
    }

    public override object GetValue(int ordinal)
    {
        EnsureRow();
        return _currentRow![ordinal] ?? DBNull.Value;
    }

    public override int GetValues(object[] values)
    {
        EnsureRow();
        var count = Math.Min(values.Length, _currentRow!.Length);
        for (var i = 0; i < count; i++)
        {
            values[i] = _currentRow[i] ?? DBNull.Value;
        }
        return count;
    }

    public override bool IsDBNull(int ordinal)
    {
        EnsureRow();
        return _currentRow![ordinal] == null || _currentRow![ordinal] == DBNull.Value;
    }

    public override bool GetBoolean(int ordinal) => (bool)GetValue(ordinal);
    public override byte GetByte(int ordinal) => (byte)GetValue(ordinal);
    public override long GetBytes(int ordinal, long dataOffset, byte[]? buffer, int bufferOffset, int length)
    {
        var data = (byte[])GetValue(ordinal);
        var available = data.Length - (int)dataOffset;
        if (available <= 0)
        {
            return 0;
        }
        var toCopy = Math.Min(available, length);
        if (buffer != null)
        {
            Buffer.BlockCopy(data, (int)dataOffset, buffer, bufferOffset, toCopy);
        }
        return toCopy;
    }

    public override char GetChar(int ordinal) => (char)GetValue(ordinal);
    public override long GetChars(int ordinal, long dataOffset, char[]? buffer, int bufferOffset, int length)
    {
        var data = GetString(ordinal).ToCharArray();
        var available = data.Length - (int)dataOffset;
        if (available <= 0)
        {
            return 0;
        }
        var toCopy = Math.Min(available, length);
        if (buffer != null)
        {
            Array.Copy(data, (int)dataOffset, buffer, bufferOffset, toCopy);
        }
        return toCopy;
    }

    public override Guid GetGuid(int ordinal) => (Guid)GetValue(ordinal);
    public override short GetInt16(int ordinal) => Convert.ToInt16(GetValue(ordinal));
    public override int GetInt32(int ordinal) => Convert.ToInt32(GetValue(ordinal));
    public override long GetInt64(int ordinal) => Convert.ToInt64(GetValue(ordinal));
    public override float GetFloat(int ordinal) => Convert.ToSingle(GetValue(ordinal));
    public override double GetDouble(int ordinal) => Convert.ToDouble(GetValue(ordinal));
    public override string GetString(int ordinal) => Convert.ToString(GetValue(ordinal)) ?? string.Empty;
    public override decimal GetDecimal(int ordinal) => Convert.ToDecimal(GetValue(ordinal));
    public override DateTime GetDateTime(int ordinal) => Convert.ToDateTime(GetValue(ordinal));

    public override IEnumerator GetEnumerator()
    {
        while (Read())
        {
            yield return _currentRow!;
        }
    }

    public override void Close()
    {
        if (_closed)
        {
            return;
        }
        _closed = true;
        if (_behavior.HasFlag(CommandBehavior.CloseConnection))
        {
            _connection?.Close();
        }
    }

    private void EnsureRow()
    {
        if (_currentRow == null)
        {
            throw new InvalidOperationException("No current row");
        }
    }
}
