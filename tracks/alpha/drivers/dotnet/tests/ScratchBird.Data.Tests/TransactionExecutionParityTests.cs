// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System;
using System.Buffers.Binary;
using System.Collections.Generic;
using System.Data;
using System.Reflection;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class TransactionExecutionParityTests
{
    [Fact]
    public void BeginTransaction_ThrowsWhenConnectionAlreadyHasActiveTransaction()
    {
        using var connection = CreateOpenConnection();
        var activeTransaction = new ScratchBirdTransaction(connection, IsolationLevel.ReadCommitted);
        SetPrivateField(connection, "_activeTransaction", activeTransaction);

        var ex = Assert.Throws<InvalidOperationException>(() => connection.BeginTransaction());
        Assert.Contains("active transaction", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void BeginTransactionWithOptions_ThrowsWhenOptionsNull()
    {
        using var connection = CreateOpenConnection();
        Assert.Throws<ArgumentNullException>(() => connection.BeginTransaction(options: null!));
    }

    [Fact]
    public void ExecuteNonQuery_ThrowsWhenCommandTextMissing()
    {
        using var connection = CreateOpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = "   ";

        var ex = Assert.Throws<InvalidOperationException>(() => command.ExecuteNonQuery());
        Assert.Contains("CommandText must be set", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void ExecuteNonQuery_ThrowsWhenConnectionHasActiveTransactionAndCommandTransactionIsMissing()
    {
        using var connection = CreateOpenConnection();
        var activeTransaction = new ScratchBirdTransaction(connection, IsolationLevel.ReadCommitted);
        SetPrivateField(connection, "_activeTransaction", activeTransaction);

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT 1";

        var ex = Assert.Throws<InvalidOperationException>(() => command.ExecuteNonQuery());
        Assert.Contains("requires an explicit Transaction", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void ExecuteNonQuery_ThrowsWhenTransactionBelongsToDifferentConnection()
    {
        using var connection = CreateOpenConnection();
        using var otherConnection = CreateOpenConnection();
        var transaction = new ScratchBirdTransaction(otherConnection, IsolationLevel.ReadCommitted);

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT 1";
        command.Transaction = transaction;

        var ex = Assert.Throws<InvalidOperationException>(() => command.ExecuteNonQuery());
        Assert.Contains("not associated", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void ExecuteNonQuery_ThrowsWhenTransactionAlreadyCompleted()
    {
        using var connection = CreateOpenConnection();
        var transaction = new ScratchBirdTransaction(connection, IsolationLevel.ReadCommitted);
        SetPrivateField(connection, "_activeTransaction", transaction);
        SetPrivateField(transaction, "_completed", true);

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT 1";
        command.Transaction = transaction;

        var ex = Assert.Throws<InvalidOperationException>(() => command.ExecuteNonQuery());
        Assert.Contains("already completed", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Savepoint_ThrowsWhenTransactionIsNotRegisteredAsActive()
    {
        using var connection = CreateOpenConnection();
        using var transaction = new ScratchBirdTransaction(connection, IsolationLevel.ReadCommitted);

        var ex = Assert.Throws<InvalidOperationException>(() => transaction.Save("s1"));
        Assert.Contains("not active", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void CommandTimeout_ThrowsForNegativeValues()
    {
        using var command = new ScratchBirdCommand();
        Assert.Throws<ArgumentOutOfRangeException>(() => command.CommandTimeout = -1);
    }

    [Fact]
    public void CommandType_AllowsStoredProcedureAndRejectsTableDirect()
    {
        using var command = new ScratchBirdCommand();
        command.CommandType = CommandType.StoredProcedure;
        Assert.Equal(CommandType.StoredProcedure, command.CommandType);
        Assert.Throws<NotSupportedException>(() => command.CommandType = CommandType.TableDirect);
    }

    [Fact]
    public void Prepare_ForStoredProcedureBuildsCallableSql()
    {
        using var connection = CreateOpenConnection();
        using var command = connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "sys.echo_value";
        command.Parameters.Add(new ScratchBirdParameter("v1", 42));
        command.Parameters.Add(new ScratchBirdParameter("v2", "ok"));

        command.Prepare();

        var prepared = (object?)GetPrivateField(command, "_preparedQuery");
        Assert.NotNull(prepared);
        var sql = (string?)prepared!.GetType().GetProperty("Sql")?.GetValue(prepared);
        Assert.Equal("CALL \"sys\".\"echo_value\"($1, $2)", sql);
    }

    [Fact]
    public void Prepare_ForStoredProcedureExcludesReturnValueFromCallableArgs()
    {
        using var connection = CreateOpenConnection();
        using var command = connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "sys.echo_value";
        command.Parameters.Add(new ScratchBirdParameter("ret", null) { Direction = ParameterDirection.ReturnValue });
        command.Parameters.Add(new ScratchBirdParameter("in1", 11) { Direction = ParameterDirection.Input });
        command.Parameters.Add(new ScratchBirdParameter("out1", null) { Direction = ParameterDirection.Output });
        command.Parameters.Add(new ScratchBirdParameter("inout1", 7) { Direction = ParameterDirection.InputOutput });

        command.Prepare();

        var prepared = (object?)GetPrivateField(command, "_preparedQuery");
        Assert.NotNull(prepared);
        var sql = (string?)prepared!.GetType().GetProperty("Sql")?.GetValue(prepared);
        Assert.Equal("CALL \"sys\".\"echo_value\"($1, $2, $3)", sql);

        var preparedParams = (IReadOnlyList<ScratchBirdParameter>?)prepared.GetType().GetProperty("Parameters")?.GetValue(prepared);
        Assert.NotNull(preparedParams);
        Assert.Equal(3, preparedParams!.Count);
        Assert.DoesNotContain(preparedParams, parameter => parameter.Direction == ParameterDirection.ReturnValue);
    }

    [Fact]
    public void ExecuteNonQuery_RejectsOutputDirectionForCommandTypeText()
    {
        using var connection = CreateOpenConnection();
        using var command = connection.CreateCommand();
        command.CommandType = CommandType.Text;
        command.CommandText = "SELECT 1";
        command.Parameters.Add(new ScratchBirdParameter("p1", null) { Direction = ParameterDirection.Output });

        var ex = Assert.Throws<NotSupportedException>(() => command.ExecuteNonQuery());
        Assert.Contains("CommandType.StoredProcedure", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void ApplyCallableOutputValues_MapsReturnOutputAndInputOutput()
    {
        var parameters = new List<ScratchBirdParameter>
        {
            new("ret", null) { Direction = ParameterDirection.ReturnValue },
            new("in1", 5) { Direction = ParameterDirection.Input },
            new("out1", null) { Direction = ParameterDirection.Output },
            new("inout1", 7) { Direction = ParameterDirection.InputOutput }
        };

        var method = typeof(ScratchBirdCommand).GetMethod(
            "ApplyCallableOutputValues",
            BindingFlags.NonPublic | BindingFlags.Static);
        Assert.NotNull(method);

        method!.Invoke(null, new object?[] { parameters, new object?[] { 99, "done", 123 } });

        Assert.Equal(99, parameters[0].Value);
        Assert.Equal("done", parameters[2].Value);
        Assert.Equal(123, parameters[3].Value);
    }

    [Fact]
    public void ApplyCallableOutputValues_SetsDbNullForMissingOutputColumns()
    {
        var parameters = new List<ScratchBirdParameter>
        {
            new("ret", null) { Direction = ParameterDirection.ReturnValue },
            new("in1", 5) { Direction = ParameterDirection.Input },
            new("out1", null) { Direction = ParameterDirection.Output },
            new("inout1", 7) { Direction = ParameterDirection.InputOutput }
        };

        var method = typeof(ScratchBirdCommand).GetMethod(
            "ApplyCallableOutputValues",
            BindingFlags.NonPublic | BindingFlags.Static);
        Assert.NotNull(method);

        method!.Invoke(null, new object?[] { parameters, new object?[] { 42 } });

        Assert.Equal(42, parameters[0].Value);
        Assert.Equal(DBNull.Value, parameters[2].Value);
        Assert.Equal(7, parameters[3].Value);
    }

    [Fact]
    public void NativeCallableSql_RewritesJdbcEscapeSyntax()
    {
        using var connection = new ScratchBirdConnection();
        var sql = connection.NativeCallableSql(
            "{ ? = call abs(?) }",
            new[]
            {
                new ScratchBirdParameter("v", -7)
            });
        Assert.Equal("select abs($1) as return_value", sql);
    }

    [Fact]
    public void ExecuteBatch_ThrowsWhenBatchParametersMissing()
    {
        using var connection = CreateOpenConnection();
        var ex = Assert.Throws<ArgumentException>(() =>
            connection.ExecuteBatch("SELECT 1", new List<IReadOnlyList<ScratchBirdParameter>>()));
        Assert.Contains("batch parameters are required", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData(IsolationLevel.Snapshot)]
    [InlineData(IsolationLevel.Chaos)]
    public void IsolationLevelSnapshotAndChaosMapToSerializable(IsolationLevel input)
    {
        var method = typeof(ProtocolClient).GetMethod(
            "MapIsolationLevel",
            BindingFlags.NonPublic | BindingFlags.Static);
        Assert.NotNull(method);
        var mapped = (byte)method!.Invoke(null, new object[] { input })!;
        Assert.Equal(ProtocolConstants.IsolationSerializable, mapped);
    }

    [Fact]
    public void CreateTxnBeginPayload_DefaultOptionsSetsReadCommittedIsolationOnly()
    {
        var payload = ProtocolClient.CreateTxnBeginPayload(new ScratchBirdTransactionOptions());

        Assert.Equal(12, payload.Length);
        Assert.Equal(ProtocolConstants.TxnFlagHasIsolation, BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(0, 2)));
        Assert.Equal(0, payload[3]); // autocommit
        Assert.Equal(ProtocolConstants.IsolationReadCommitted, payload[4]);
        Assert.Equal(0, payload[5]); // access
        Assert.Equal(0, payload[6]); // deferrable
        Assert.Equal(0, payload[7]); // wait
        Assert.Equal(0u, BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(8, 4)));
    }

    [Fact]
    public void CreateTxnBeginPayload_WithOptionalsSetsFlagsAndFields()
    {
        var payload = ProtocolClient.CreateTxnBeginPayload(new ScratchBirdTransactionOptions
        {
            IsolationLevel = IsolationLevel.Serializable,
            AccessMode = ScratchBirdTransactionAccessMode.ReadOnly,
            Deferrable = true,
            Wait = false,
            TimeoutMs = 1500,
            AutoCommit = true
        });

        var expectedFlags =
            ProtocolConstants.TxnFlagHasIsolation |
            ProtocolConstants.TxnFlagHasAccess |
            ProtocolConstants.TxnFlagHasDeferrable |
            ProtocolConstants.TxnFlagHasWait |
            ProtocolConstants.TxnFlagHasTimeout |
            ProtocolConstants.TxnFlagHasAutocommit;

        Assert.Equal(expectedFlags, BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(0, 2)));
        Assert.Equal(1, payload[3]); // autocommit true
        Assert.Equal(ProtocolConstants.IsolationSerializable, payload[4]);
        Assert.Equal((byte)ScratchBirdTransactionAccessMode.ReadOnly, payload[5]);
        Assert.Equal(1, payload[6]); // deferrable true
        Assert.Equal(0, payload[7]); // wait false
        Assert.Equal(1500u, BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(8, 4)));
    }

    [Fact]
    public void CreateTxnBeginPayload_ThrowsWhenTimeoutIsNegative()
    {
        var ex = Assert.Throws<ArgumentOutOfRangeException>(() =>
            ProtocolClient.CreateTxnBeginPayload(new ScratchBirdTransactionOptions { TimeoutMs = -1 }));
        Assert.Contains("TimeoutMs", ex.Message, StringComparison.Ordinal);
    }

    private static ScratchBirdConnection CreateOpenConnection()
    {
        var connection = new ScratchBirdConnection("Host=localhost;Port=13092;Database=main;Username=sb_admin;Password=SbAdmin_Compat1!;Pooling=false");
        SetPrivateField(connection, "_state", ConnectionState.Open);
        return connection;
    }

    private static void SetPrivateField(object target, string fieldName, object? value)
    {
        var field = target.GetType().GetField(fieldName, BindingFlags.Instance | BindingFlags.NonPublic);
        Assert.NotNull(field);
        field!.SetValue(target, value);
    }

    private static object? GetPrivateField(object target, string fieldName)
    {
        var field = target.GetType().GetField(fieldName, BindingFlags.Instance | BindingFlags.NonPublic);
        Assert.NotNull(field);
        return field!.GetValue(target);
    }
}
