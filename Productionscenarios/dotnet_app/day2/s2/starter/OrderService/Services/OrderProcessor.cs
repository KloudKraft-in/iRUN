using Retail.Core;

namespace Retail.Services;

public sealed record OrderSummary(string CustomerId, decimal Subtotal, decimal Discount, decimal Total, string Rule);

public sealed class OrderProcessor
{
    private readonly IDiscountRule _discountRule;

    // The DI container must be able to supply an IDiscountRule, or this class cannot be created.
    public OrderProcessor(IDiscountRule discountRule) => _discountRule = discountRule;

    public OrderSummary Price(string customerId, decimal subtotal)
    {
        var discount = _discountRule.Apply(subtotal);
        return new OrderSummary(customerId, subtotal, discount, subtotal - discount, _discountRule.Name);
    }
}

