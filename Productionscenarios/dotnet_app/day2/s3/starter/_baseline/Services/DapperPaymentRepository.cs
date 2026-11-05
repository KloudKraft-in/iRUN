using Dapper;
using Microsoft.Data.SqlClient;

namespace PaymentApi.Services;

public sealed class DapperPaymentRepository : IPaymentRepository
{
    private readonly string _connectionString;

    public DapperPaymentRepository(IConfiguration configuration) =>
        _connectionString = configuration.GetConnectionString("RetailPerformanceDb")
            ?? throw new InvalidOperationException("Connection string 'RetailPerformanceDb' is missing.");

    public async Task<int> ProcessPaymentAsync(int orderId, decimal amount)
    {
        var connection = new SqlConnection(_connectionString);

        AppDomain.CurrentDomain.ProcessExit += (_, _) => connection.Dispose();

        await connection.OpenAsync();

        return await connection.ExecuteScalarAsync<int>(
            "INSERT INTO Payments (OrderId, Amount, Status, CreatedUtc) " +
            "OUTPUT INSERTED.Id VALUES (@OrderId, @Amount, 'Captured', SYSUTCDATETIME())",
            new { OrderId = orderId, Amount = amount });
    }
}

