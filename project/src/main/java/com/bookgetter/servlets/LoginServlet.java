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

@WebServlet("/api/login")
public class LoginServlet extends HttpServlet {
    private UserService userService = UserService.getInstance();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            String requestBody = request.getReader().lines()
                .reduce("", (accumulator, actual) -> accumulator + actual);

            Map<String, String> credentials = JsonUtil.fromJson(requestBody,
                new com.google.gson.reflect.TypeToken<Map<String, String>>(){}.getType());

            String username = credentials.get("username");
            String password = credentials.get("password");
            String requestedRole = credentials.get("role");

            if (username == null || password == null || requestedRole == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "Username, password, and role are required");
                response.getWriter().write(JsonUtil.toJson(result));
                return;
            }

            User user = userService.login(username, password);

            if (user != null) {
                if (!user.getRole().equals(requestedRole)) {
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", false);
                    result.put("message", "This account is not registered as " + requestedRole);
                    response.getWriter().write(JsonUtil.toJson(result));
                    return;
                }

                SessionUtil.setCurrentUser(request, user);

                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                result.put("user", user);

                response.getWriter().write(JsonUtil.toJson(result));
            } else {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                Map<String, Object> result = new HashMap<>();
                result.put("success", false);
                result.put("message", "Invalid username or password");
                response.getWriter().write(JsonUtil.toJson(result));
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
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        User user = SessionUtil.getCurrentUser(request);

        Map<String, Object> result = new HashMap<>();
        result.put("loggedIn", user != null);
        if (user != null) {
            result.put("user", user);
        }

        response.getWriter().write(JsonUtil.toJson(result));
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        SessionUtil.removeCurrentUser(request);

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("message", "Logged out successfully");

        response.getWriter().write(JsonUtil.toJson(result));
    }
}
