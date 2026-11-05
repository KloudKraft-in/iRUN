using Microsoft.EntityFrameworkCore;

namespace PaymentApi.Data;

public static class DbSeeder
{
    /// <summary>Drops, re-creates and seeds RetailPerformanceDb: 50 customers, 200 orders, 2-4 items each. Deterministic.</summary>
    public static async Task ResetAsync(RetailDbContext db)
    {
        await db.Database.EnsureDeletedAsync();
        await db.Database.EnsureCreatedAsync();

        var rnd = new Random(42);
        var customers = Enumerable.Range(1, 50).Select(i => new Customer { Name = $"Customer {i:000}" }).ToList();
        db.Customers.AddRange(customers);
        await db.SaveChangesAsync();

        var orders = new List<Order>();
        for (var i = 1; i <= 200; i++)
        {
            var items = Enumerable.Range(1, rnd.Next(2, 5)).Select(_ => new OrderItem
            {
                Sku = $"SKU-{rnd.Next(1, 40):000}",
                Quantity = rnd.Next(1, 4),
                UnitPrice = Math.Round((decimal)(rnd.NextDouble() * 90 + 10), 2)
            }).ToList();

            orders.Add(new Order
            {
                CustomerId = customers[rnd.Next(customers.Count)].Id,
                CreatedUtc = DateTime.UtcNow.AddMinutes(-i),
                Items = items,
                Total = items.Sum(x => x.Quantity * x.UnitPrice)
            });
        }
        db.Orders.AddRange(orders);
        await db.SaveChangesAsync();
    }
}
