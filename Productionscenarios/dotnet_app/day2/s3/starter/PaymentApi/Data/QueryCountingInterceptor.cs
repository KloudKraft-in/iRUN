using System.Data.Common;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace PaymentApi.Data;

public sealed class QueryCountingInterceptor : DbCommandInterceptor
{
    public override InterceptionResult<DbDataReader> ReaderExecuting(
        DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result)
    {
        Count(eventData);
        return base.ReaderExecuting(command, eventData, result);
    }

    public override ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(
        DbCommand command, CommandEventData eventData, InterceptionResult<DbDataReader> result,
        CancellationToken cancellationToken = default)
    {
        Count(eventData);
        return base.ReaderExecutingAsync(command, eventData, result, cancellationToken);
    }

    private static void Count(CommandEventData eventData)
    {
        if (eventData.Context is RetailDbContext db) db.QueryCount++;
    }
}

