namespace PaymentApi.Services;

public interface IPaymentRepository
{
    /// <summary>Records a captured payment and returns its new Id.</summary>
    Task<int> ProcessPaymentAsync(int orderId, decimal amount);
}

