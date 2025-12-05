package com.bookgetter.servlets;

import com.bookgetter.models.Cart;
import com.bookgetter.models.Order;
import com.bookgetter.models.OrderItem;
import com.bookgetter.models.User;
import com.bookgetter.services.CartService;
import com.bookgetter.services.OrderService;
import com.bookgetter.utils.JsonUtil;
import com.bookgetter.utils.SessionUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/api/orders")
public class OrderServlet extends HttpServlet {
    private OrderService orderService = OrderService.getInstance();
    private CartService cartService = CartService.getInstance();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        if (!SessionUtil.requireLogin(request, response)) {
            return;
        }

        try {
            User user = SessionUtil.getCurrentUser(request);

            if ("admin".equals(user.getRole())) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "Administrators cannot access customer orders");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            String orderId = request.getParameter("id");

            if (orderId != null) {
                Order order = orderService.getOrderById(orderId);
                if (order != null && order.getUserId().equals(user.getId())) {
                    response.getWriter().write(JsonUtil.toJson(order));
                } else {
                    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", false);
                    result.put("message", "Order not found");
                    response.getWriter().write(JsonUtil.toJson(result));
                }
            } else {
                List<Order> orders = orderService.getOrdersByUserId(user.getId());
                response.getWriter().write(JsonUtil.toJson(orders));
            }
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            response.getWriter().write(JsonUtil.toJson(result));
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        if (!SessionUtil.requireLogin(request, response)) {
            return;
        }

        try {
            User user = SessionUtil.getCurrentUser(request);

            String requestBody = request.getReader().lines()
                .reduce("", (accumulator, actual) -> accumulator + actual);

            Map<String, String> data = JsonUtil.fromJson(requestBody,
                new com.google.gson.reflect.TypeToken<Map<String, String>>(){}.getType());

            String shippingAddress = data.get("shippingAddress");
            String phone = data.get("phone");

            if (shippingAddress == null || phone == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "Shipping address and phone are required");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            Cart cart = cartService.getOrCreateCart(user.getId());

            if (cart.getItems().isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "Cart is empty");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            List<OrderItem> orderItems = new ArrayList<>();
            for (var cartItem : cart.getItems()) {
                OrderItem item = new OrderItem(
                    cartItem.getBookId(),
                    cartItem.getBookTitle(),
                    cartItem.getBookAuthor(),
                    cartItem.getPrice(),
                    cartItem.getQuantity()
                );
                orderItems.add(item);
            }

            double totalAmount = cart.getTotalAmount();

            Order order = orderService.createOrder(
                user.getId(),
                orderItems,
                totalAmount,
                shippingAddress,
                phone
            );

            cartService.clearCart(user.getId());

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("order", order);
            response.getWriter().write(JsonUtil.toJson(result));
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            response.getWriter().write(JsonUtil.toJson(result));
        }
    }
}
