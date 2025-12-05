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

@WebServlet("/api/register")
public class RegisterServlet extends HttpServlet {
    private UserService userService = UserService.getInstance();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            String requestBody = request.getReader().lines()
                .reduce("", (accumulator, actual) -> accumulator + actual);

            Map<String, String> data = JsonUtil.fromJson(requestBody,
                new com.google.gson.reflect.TypeToken<Map<String, String>>(){}.getType());

            String username = data.get("username");
            String password = data.get("password");
            String email = data.get("email");

            if (username == null || password == null || email == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "All fields are required");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            if (password.length() < 6) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "Password must be at least 6 characters long");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            User user = userService.register(username, password, email, "customer");
            SessionUtil.setCurrentUser(request, user);

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("user", user);

            response.getWriter().write(JsonUtil.toJson(result));
        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
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
