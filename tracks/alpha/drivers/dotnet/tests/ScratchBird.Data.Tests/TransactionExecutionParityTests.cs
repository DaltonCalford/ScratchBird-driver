// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System;
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
}
