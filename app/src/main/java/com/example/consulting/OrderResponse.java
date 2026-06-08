package com.example.consulting;

import java.time.LocalDateTime;

public record OrderResponse(
        Long id,
        String customerName,
        String productName,
        Integer quantity,
        OrderStatus status,
        LocalDateTime createdAt
) {
    public static OrderResponse from(Order order) {
        return new OrderResponse(
                order.getId(),
                order.getCustomerName(),
                order.getProductName(),
                order.getQuantity(),
                order.getStatus(),
                order.getCreatedAt()
        );
    }
}
