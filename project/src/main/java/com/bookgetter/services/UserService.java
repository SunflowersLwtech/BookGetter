package com.bookgetter.services;

import com.bookgetter.models.User;
import com.bookgetter.utils.FileUtil;
import com.bookgetter.utils.JsonUtil;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class UserService {
    private static final String USERS_FILE = "users.json";
    private static UserService instance;

    private UserService() {}

    public static synchronized UserService getInstance() {
        if (instance == null) {
            instance = new UserService();
        }
        return instance;
    }

    private List<User> loadUsers() throws IOException {
        if (!FileUtil.fileExists(USERS_FILE)) {
            return new ArrayList<>();
        }
        String json = FileUtil.readFile(USERS_FILE);
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        Type listType = new TypeToken<List<User>>(){}.getType();
        return JsonUtil.fromJson(json, listType);
    }

    private void saveUsers(List<User> users) throws IOException {
        String json = JsonUtil.toJson(users);
        FileUtil.writeFile(USERS_FILE, json);
    }

    public User register(String username, String password, String email, String role) throws IOException {
        List<User> users = loadUsers();

        Optional<User> existing = users.stream()
            .filter(u -> u.getUsername().equals(username))
            .findFirst();

        if (existing.isPresent()) {
            throw new IllegalArgumentException("Username already exists");
        }

        Optional<User> existingEmail = users.stream()
            .filter(u -> u.getEmail().equals(email))
            .findFirst();

        if (existingEmail.isPresent()) {
            throw new IllegalArgumentException("Email already exists");
        }

        User user = new User(username, password, email, role);
        users.add(user);
        saveUsers(users);
        return user;
    }

    public User login(String username, String password) throws IOException {
        List<User> users = loadUsers();
        return users.stream()
            .filter(u -> u.getUsername().equals(username) && u.getPassword().equals(password))
            .findFirst()
            .orElse(null);
    }

    public User getUserById(String userId) throws IOException {
        List<User> users = loadUsers();
        return users.stream()
            .filter(u -> u.getId().equals(userId))
            .findFirst()
            .orElse(null);
    }

    public User updateUser(User user) throws IOException {
        List<User> users = loadUsers();
        for (int i = 0; i < users.size(); i++) {
            if (users.get(i).getId().equals(user.getId())) {
                users.set(i, user);
                saveUsers(users);
                return user;
            }
        }
        throw new IllegalArgumentException("User not found");
    }

    public List<User> getAllUsers() throws IOException {
        return loadUsers();
    }
}
