package com.bookgetter.servlets;

import com.bookgetter.models.Book;
import com.bookgetter.models.Cart;
import com.bookgetter.models.User;
import com.bookgetter.services.BookService;
import com.bookgetter.services.CartService;
import com.bookgetter.utils.JsonUtil;
import com.bookgetter.utils.SessionUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/api/cart")
public class CartServlet extends HttpServlet {
    private CartService cartService = CartService.getInstance();
    private BookService bookService = BookService.getInstance();

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
                result.put("message", "Administrators cannot access shopping cart");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            Cart cart = cartService.getOrCreateCart(user.getId());
            response.getWriter().write(JsonUtil.toJson(cart));
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

            Map<String, Object> data = JsonUtil.fromJson(requestBody,
                new com.google.gson.reflect.TypeToken<Map<String, Object>>(){}.getType());

            String bookId = (String) data.get("bookId");
            int quantity = ((Double) data.get("quantity")).intValue();

            Book book = bookService.getBookById(bookId);
            if (book == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "Book not found");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            if (book.getStock() < quantity) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "Insufficient stock");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            Cart cart = cartService.addToCart(user.getId(), book, quantity);

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("cart", cart);
            response.getWriter().write(JsonUtil.toJson(result));
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            response.getWriter().write(JsonUtil.toJson(result));
        }
    }

    @Override
    protected void doPut(HttpServletRequest request, HttpServletResponse response)
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

            Map<String, Object> data = JsonUtil.fromJson(requestBody,
                new com.google.gson.reflect.TypeToken<Map<String, Object>>(){}.getType());

            String bookId = (String) data.get("bookId");
            int quantity = ((Double) data.get("quantity")).intValue();

            if (quantity > 0) {
                Book book = bookService.getBookById(bookId);
                if (book == null) {
                    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", false);
                    result.put("message", "Book not found");
                    response.getWriter().write(JsonUtil.toJson(result));
                    return;
                }

                if (quantity > book.getStock()) {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", false);
                    result.put("message", "Cannot add more items. Only " + book.getStock() + " remaining in stock.");
                    response.getWriter().write(JsonUtil.toJson(result));
                    return;
                }
            }

            Cart cart = cartService.updateCartItem(user.getId(), bookId, quantity);

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("cart", cart);
            response.getWriter().write(JsonUtil.toJson(result));
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            response.getWriter().write(JsonUtil.toJson(result));
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        if (!SessionUtil.requireLogin(request, response)) {
            return;
        }

        try {
            User user = SessionUtil.getCurrentUser(request);
            cartService.clearCart(user.getId());

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", "Cart cleared");
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
