package com.bookgetter.services;

import com.bookgetter.models.Order;
import com.bookgetter.models.OrderItem;
import com.bookgetter.utils.FileUtil;
import com.bookgetter.utils.JsonUtil;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class OrderService {
    private static final String ORDERS_FILE = "orders.json";
    private static OrderService instance;

    private OrderService() {}

    public static synchronized OrderService getInstance() {
        if (instance == null) {
            instance = new OrderService();
        }
        return instance;
    }

    private List<Order> loadOrders() throws IOException {
        if (!FileUtil.fileExists(ORDERS_FILE)) {
            return new ArrayList<>();
        }
        String json = FileUtil.readFile(ORDERS_FILE);
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        Type listType = new TypeToken<List<Order>>(){}.getType();
        return JsonUtil.fromJson(json, listType);
    }

    private void saveOrders(List<Order> orders) throws IOException {
        String json = JsonUtil.toJson(orders);
        FileUtil.writeFile(ORDERS_FILE, json);
    }

    public Order createOrder(String userId, List<OrderItem> items, double totalAmount,
                            String shippingAddress, String phone) throws IOException {
        List<Order> orders = loadOrders();
        Order order = new Order(userId, items, totalAmount, shippingAddress, phone);
        orders.add(order);
        saveOrders(orders);

        BookService bookService = BookService.getInstance();
        for (OrderItem item : items) {
            bookService.updateStock(item.getBookId(), item.getQuantity());
        }

        return order;
    }

    public List<Order> getOrdersByUserId(String userId) throws IOException {
        List<Order> orders = loadOrders();
        return orders.stream()
            .filter(o -> o.getUserId().equals(userId))
            .collect(Collectors.toList());
    }

    public Order getOrderById(String orderId) throws IOException {
        List<Order> orders = loadOrders();
        return orders.stream()
            .filter(o -> o.getId().equals(orderId))
            .findFirst()
            .orElse(null);
    }

    public List<Order> getAllOrders() throws IOException {
        return loadOrders();
    }

    public Order updateOrderStatus(String orderId, String status) throws IOException {
        List<Order> orders = loadOrders();
        for (Order order : orders) {
            if (order.getId().equals(orderId)) {
                order.setStatus(status);
                saveOrders(orders);
                return order;
            }
        }
        throw new IllegalArgumentException("Order not found");
    }
}
