package com.example.consulting;

import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class OrderController {

    private static final Logger log = LoggerFactory.getLogger(OrderController.class);

    private final OrderRepository orderRepository;

    public OrderController(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    @GetMapping("/health")
    public HealthResponse health() {
        return new HealthResponse("UP", "consulting-orders-api", Instant.now());
    }

    @GetMapping("/orders")
    public List<OrderResponse> findOrders() {
        log.info("Listing orders");
        return orderRepository.findAll()
                .stream()
                .map(OrderResponse::from)
                .toList();
    }

    @PostMapping("/orders")
    @ResponseStatus(HttpStatus.CREATED)
    public OrderResponse createOrder(@Valid @RequestBody CreateOrderRequest request) {
        log.info("Creating order customer={} product={} quantity={}",
                request.customerName(), request.productName(), request.quantity());
        Order saved = orderRepository.save(new Order(
                request.customerName(),
                request.productName(),
                request.quantity()
        ));
        return OrderResponse.from(saved);
    }

    @GetMapping("/error-test")
    public void errorTest() {
        log.error("Simulated application error for logging and alert testing");
        throw new IllegalStateException("Simulated incident for Loki and Alertmanager test");
    }
}
