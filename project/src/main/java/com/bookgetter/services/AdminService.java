package com.bookgetter.services;

import com.bookgetter.models.Book;
import com.bookgetter.models.Order;
import com.bookgetter.models.User;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AdminService {
    private static AdminService instance;

    private AdminService() {}

    public static synchronized AdminService getInstance() {
        if (instance == null) {
            instance = new AdminService();
        }
        return instance;
    }

    public Map<String, Object> getDashboardStats() throws IOException {
        BookService bookService = BookService.getInstance();
        OrderService orderService = OrderService.getInstance();
        UserService userService = UserService.getInstance();

        List<Book> books = bookService.getAllBooks();
        List<Order> orders = orderService.getAllOrders();
        List<User> users = userService.getAllUsers();

        long customerCount = users.stream()
            .filter(u -> "customer".equals(u.getRole()))
            .count();

        double totalRevenue = orders.stream()
            .mapToDouble(Order::getTotalAmount)
            .sum();

        long pendingOrders = orders.stream()
            .filter(o -> "pending".equals(o.getStatus()))
            .count();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalBooks", books.size());
        stats.put("totalOrders", orders.size());
        stats.put("totalCustomers", customerCount);
        stats.put("totalRevenue", totalRevenue);
        stats.put("pendingOrders", pendingOrders);
        stats.put("totalUsers", users.size());

        return stats;
    }

    public List<Book> getAllBooks() throws IOException {
        return BookService.getInstance().getAllBooks();
    }

    public List<Order> getAllOrders() throws IOException {
        return OrderService.getInstance().getAllOrders();
    }

    public List<User> getAllUsers() throws IOException {
        return UserService.getInstance().getAllUsers();
    }

    public Book addBook(Book book) throws IOException {
        return BookService.getInstance().addBook(book);
    }

    public Book updateBook(Book book) throws IOException {
        return BookService.getInstance().updateBook(book);
    }

    public void deleteBook(String bookId) throws IOException {
        BookService.getInstance().deleteBook(bookId);
    }

    public Order updateOrderStatus(String orderId, String status) throws IOException {
        return OrderService.getInstance().updateOrderStatus(orderId, status);
    }
}
