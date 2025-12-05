package com.bookgetter.servlets;

import com.bookgetter.models.User;
import com.bookgetter.services.UserService;
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

@WebServlet("/api/user")
public class UserServlet extends HttpServlet {
    private UserService userService = UserService.getInstance();

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
            response.getWriter().write(JsonUtil.toJson(user));
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
            User currentUser = SessionUtil.getCurrentUser(request);

            String requestBody = request.getReader().lines()
                .reduce("", (accumulator, actual) -> accumulator + actual);

            User updatedData = JsonUtil.fromJson(requestBody, User.class);

            currentUser.setEmail(updatedData.getEmail());
            currentUser.setAddress(updatedData.getAddress());
            currentUser.setPhone(updatedData.getPhone());

            if (updatedData.getPassword() != null && !updatedData.getPassword().isEmpty()) {
                currentUser.setPassword(updatedData.getPassword());
            }

            User savedUser = userService.updateUser(currentUser);
            SessionUtil.setCurrentUser(request, savedUser);

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("user", savedUser);
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
