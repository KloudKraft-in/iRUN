namespace Retail.Core;

public interface IDiscountRule
{
    string Name { get; }
    decimal Apply(decimal subtotal);
}

