using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace PaymentApi.Data;

public class Customer
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public List<Order> Orders { get; set; } = new();
}

public class Order
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public Customer? Customer { get; set; }
    public List<OrderItem> Items { get; set; } = new();
    [Column(TypeName = "decimal(18,2)")] public decimal Total { get; set; }
    public DateTime CreatedUtc { get; set; }
}

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public string Sku { get; set; } = "";
    public int Quantity { get; set; }
    [Column(TypeName = "decimal(18,2)")] public decimal UnitPrice { get; set; }
}

public class Payment
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    [Column(TypeName = "decimal(18,2)")] public decimal Amount { get; set; }
    public string Status { get; set; } = "";
    public DateTime CreatedUtc { get; set; }
}

public class RetailDbContext : DbContext
{
    public RetailDbContext(DbContextOptions<RetailDbContext> options) : base(options) { }

    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Payment> Payments => Set<Payment>();

    public int QueryCount { get; set; }
}

