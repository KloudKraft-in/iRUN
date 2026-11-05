using Retail.Core;

namespace Retail.Services;

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

