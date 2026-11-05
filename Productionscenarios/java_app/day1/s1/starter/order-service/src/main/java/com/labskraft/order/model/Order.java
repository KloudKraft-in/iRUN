package com.labskraft.order.model;

/**
 * Order response model.
 */
public class Order {
    private Long productId;
    private String productName;
    private Integer quantity;
    private Double totalPrice;

    public Order() {}

    public Order(Long productId, String productName, Integer quantity, Double totalPrice) {
        this.productId = productId;
        this.productName = productName;
        this.quantity = quantity;
        this.totalPrice = totalPrice;
    }

    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public Double getTotalPrice() { return totalPrice; }
    public void setTotalPrice(Double totalPrice) { this.totalPrice = totalPrice; }
}
