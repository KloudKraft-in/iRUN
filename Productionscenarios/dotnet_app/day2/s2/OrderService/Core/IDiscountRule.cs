namespace Retail.Core;

/// <summary>A pricing rule that returns the discount AMOUNT for an order subtotal.</summary>
public interface IDiscountRule
{
    string Name { get; }
    decimal Apply(decimal subtotal);
}
