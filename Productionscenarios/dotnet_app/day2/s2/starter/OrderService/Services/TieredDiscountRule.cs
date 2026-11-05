using Retail.Core;

namespace Retail.Services;

/// <summary>10% off orders of 1000 or more, 5% off orders of 500 or more, otherwise nothing.</summary>
public sealed class TieredDiscountRule : IDiscountRule
{
    public string Name => "Tiered";

    public decimal Apply(decimal subtotal) => subtotal switch
    {
        >= 1000m => Math.Round(subtotal * 0.10m, 2),
        >= 500m  => Math.Round(subtotal * 0.05m, 2),
        _        => 0m
    };
}

