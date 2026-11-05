using Microsoft.EntityFrameworkCore;
using PaymentApi.Data;

namespace PaymentApi.Services;

public sealed record OrderSummaryDto(int OrderId, string CustomerName, int ItemCount, decimal Total);
public sealed record OrderSummaryResult(int QueryCount, IReadOnlyList<OrderSummaryDto> Orders);

public sealed class OrderQueryService
{
    private readonly RetailDbContext _db;

    public OrderQueryService(RetailDbContext db) => _db = db;

    public async Task<OrderSummaryResult> GetOrderSummariesAsync()
    {
        var orders = await _db.Orders.AsNoTracking().ToListAsync();

        var list = new List<OrderSummaryDto>();
        foreach (var order in orders)
        {
            var customer = await _db.Customers.AsNoTracking().FirstAsync(c => c.Id == order.CustomerId);
            var items = await _db.OrderItems.AsNoTracking().Where(i => i.OrderId == order.Id).ToListAsync();
            list.Add(new OrderSummaryDto(order.Id, customer.Name, items.Count, order.Total));
        }

        return new OrderSummaryResult(_db.QueryCount, list);
    }
}

