namespace PaymentApi.Services;

public interface IPaymentRepository
{
    Task<int> ProcessPaymentAsync(int orderId, decimal amount);
}

