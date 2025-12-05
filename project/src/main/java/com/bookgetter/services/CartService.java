package com.bookgetter.services;

import com.bookgetter.models.Cart;
import com.bookgetter.models.CartItem;
import com.bookgetter.models.Book;
import com.bookgetter.utils.FileUtil;
import com.bookgetter.utils.JsonUtil;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;

public class CartService {
    private static final String CARTS_FILE = "carts.json";
    private static CartService instance;
    private BookService bookService = BookService.getInstance();

    private CartService() {}

    public static synchronized CartService getInstance() {
        if (instance == null) {
            instance = new CartService();
        }
        return instance;
    }

    private List<Cart> loadCarts() throws IOException {
        if (!FileUtil.fileExists(CARTS_FILE)) {
            return new ArrayList<>();
        }
        String json = FileUtil.readFile(CARTS_FILE);
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        Type listType = new TypeToken<List<Cart>>(){}.getType();
        return JsonUtil.fromJson(json, listType);
    }

    private void saveCarts(List<Cart> carts) throws IOException {
        String json = JsonUtil.toJson(carts);
        FileUtil.writeFile(CARTS_FILE, json);
    }

    public Cart getOrCreateCart(String userId) throws IOException {
        List<Cart> carts = loadCarts();
        Cart cart = carts.stream()
            .filter(c -> c.getUserId().equals(userId))
            .findFirst()
            .orElse(null);

        if (cart == null) {
            cart = new Cart(userId);
            carts.add(cart);
            saveCarts(carts);
        }

        enrichCartWithStock(cart);
        return cart;
    }

    private void enrichCartWithStock(Cart cart) throws IOException {
        for (CartItem item : cart.getItems()) {
            Book book = bookService.getBookById(item.getBookId());
            if (book != null) {
                item.setAvailableStock(book.getStock());
            }
        }
    }

    public Cart addToCart(String userId, Book book, int quantity) throws IOException {
        List<Cart> carts = loadCarts();
        Cart cart = carts.stream()
            .filter(c -> c.getUserId().equals(userId))
            .findFirst()
            .orElse(null);

        if (cart == null) {
            cart = new Cart(userId);
            carts.add(cart);
        }

        CartItem existingItem = cart.getItems().stream()
            .filter(item -> item.getBookId().equals(book.getId()))
            .findFirst()
            .orElse(null);

        if (existingItem != null) {
            existingItem.setQuantity(existingItem.getQuantity() + quantity);
            existingItem.setAvailableStock(book.getStock());
        } else {
            CartItem newItem = new CartItem(
                book.getId(),
                book.getTitle(),
                book.getAuthor(),
                book.getPrice(),
                quantity,
                book.getImageUrl(),
                book.getStock()
            );
            cart.getItems().add(newItem);
        }

        cart.setUpdatedAt(System.currentTimeMillis());
        saveCarts(carts);
        enrichCartWithStock(cart);
        return cart;
    }

    public Cart updateCartItem(String userId, String bookId, int quantity) throws IOException {
        List<Cart> carts = loadCarts();
        Cart cart = carts.stream()
            .filter(c -> c.getUserId().equals(userId))
            .findFirst()
            .orElse(null);

        if (cart == null) {
            throw new IllegalArgumentException("Cart not found");
        }

        if (quantity <= 0) {
            cart.getItems().removeIf(item -> item.getBookId().equals(bookId));
        } else {
            CartItem item = cart.getItems().stream()
                .filter(i -> i.getBookId().equals(bookId))
                .findFirst()
                .orElse(null);
            if (item != null) {
                item.setQuantity(quantity);
            }
        }

        cart.setUpdatedAt(System.currentTimeMillis());
        saveCarts(carts);
        enrichCartWithStock(cart);
        return cart;
    }

    public void clearCart(String userId) throws IOException {
        List<Cart> carts = loadCarts();
        Cart cart = carts.stream()
            .filter(c -> c.getUserId().equals(userId))
            .findFirst()
            .orElse(null);

        if (cart != null) {
            cart.getItems().clear();
            cart.setUpdatedAt(System.currentTimeMillis());
            saveCarts(carts);
        }
    }
}
