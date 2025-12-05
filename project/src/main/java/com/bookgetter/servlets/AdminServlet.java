package com.bookgetter.servlets;

import com.bookgetter.models.Book;
import com.bookgetter.services.AdminService;
import com.bookgetter.utils.JsonUtil;
import com.bookgetter.utils.SessionUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/api/admin/*")
public class AdminServlet extends HttpServlet {
    private AdminService adminService = AdminService.getInstance();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        if (!SessionUtil.requireAdmin(request, response)) {
            return;
        }

        try {
            String pathInfo = request.getPathInfo();

            if (pathInfo == null || pathInfo.equals("/") || pathInfo.equals("/stats")) {
                Map<String, Object> stats = adminService.getDashboardStats();
                response.getWriter().write(JsonUtil.toJson(stats));
            } else if (pathInfo.equals("/books")) {
                List<Book> books = adminService.getAllBooks();
                response.getWriter().write(JsonUtil.toJson(books));
            } else if (pathInfo.equals("/orders")) {
                response.getWriter().write(JsonUtil.toJson(adminService.getAllOrders()));
            } else if (pathInfo.equals("/users")) {
                response.getWriter().write(JsonUtil.toJson(adminService.getAllUsers()));
            } else {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
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

        if (!SessionUtil.requireAdmin(request, response)) {
            return;
        }

        try {
            String pathInfo = request.getPathInfo();

            if (pathInfo != null && pathInfo.equals("/books")) {
                String requestBody = request.getReader().lines()
                    .reduce("", (accumulator, actual) -> accumulator + actual);

                Book book = JsonUtil.fromJson(requestBody, Book.class);
                Book created = adminService.addBook(book);

                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                result.put("book", created);
                response.getWriter().write(JsonUtil.toJson(result));
            } else {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
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
    protected void doPut(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        if (!SessionUtil.requireAdmin(request, response)) {
            return;
        }

        try {
            String pathInfo = request.getPathInfo();
            String requestBody = request.getReader().lines()
                .reduce("", (accumulator, actual) -> accumulator + actual);

            if (pathInfo != null && pathInfo.startsWith("/books/")) {
                Book book = JsonUtil.fromJson(requestBody, Book.class);
                Book updated = adminService.updateBook(book);

                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                result.put("book", updated);
                response.getWriter().write(JsonUtil.toJson(result));
            } else if (pathInfo != null && pathInfo.startsWith("/orders/")) {
                String orderId = pathInfo.substring("/orders/".length());
                Map<String, String> data = JsonUtil.fromJson(requestBody,
                    new com.google.gson.reflect.TypeToken<Map<String, String>>(){}.getType());

                String status = data.get("status");
                adminService.updateOrderStatus(orderId, status);

                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                response.getWriter().write(JsonUtil.toJson(result));
            } else {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
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
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        if (!SessionUtil.requireAdmin(request, response)) {
            return;
        }

        try {
            String pathInfo = request.getPathInfo();

            if (pathInfo != null && pathInfo.startsWith("/books/")) {
                String bookId = pathInfo.substring("/books/".length());
                adminService.deleteBook(bookId);

                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                response.getWriter().write(JsonUtil.toJson(result));
            } else {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            response.getWriter().write(JsonUtil.toJson(result));
        }
    }
}
