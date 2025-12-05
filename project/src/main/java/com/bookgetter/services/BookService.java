package com.bookgetter.services;

import com.bookgetter.models.Book;
import com.bookgetter.utils.FileUtil;
import com.bookgetter.utils.JsonUtil;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class BookService {
    private static final String BOOKS_FILE = "books.json";
    private static BookService instance;

    private BookService() {}

    public static synchronized BookService getInstance() {
        if (instance == null) {
            instance = new BookService();
        }
        return instance;
    }

    private List<Book> loadBooks() throws IOException {
        if (!FileUtil.fileExists(BOOKS_FILE)) {
            return new ArrayList<>();
        }
        String json = FileUtil.readFile(BOOKS_FILE);
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        Type listType = new TypeToken<List<Book>>(){}.getType();
        return JsonUtil.fromJson(json, listType);
    }

    private void saveBooks(List<Book> books) throws IOException {
        String json = JsonUtil.toJson(books);
        FileUtil.writeFile(BOOKS_FILE, json);
    }

    public List<Book> getAllBooks() throws IOException {
        return loadBooks();
    }

    public Book getBookById(String bookId) throws IOException {
        List<Book> books = loadBooks();
        return books.stream()
            .filter(b -> b.getId().equals(bookId))
            .findFirst()
            .orElse(null);
    }

    public List<Book> searchBooks(String query) throws IOException {
        List<Book> books = loadBooks();
        String lowerQuery = query.toLowerCase();
        return books.stream()
            .filter(b -> b.getTitle().toLowerCase().contains(lowerQuery) ||
                        b.getAuthor().toLowerCase().contains(lowerQuery) ||
                        b.getCategory().toLowerCase().contains(lowerQuery))
            .collect(Collectors.toList());
    }

    public List<Book> getBooksByCategory(String category) throws IOException {
        List<Book> books = loadBooks();
        return books.stream()
            .filter(b -> b.getCategory().equalsIgnoreCase(category))
            .collect(Collectors.toList());
    }

    public Book addBook(Book book) throws IOException {
        List<Book> books = loadBooks();
        books.add(book);
        saveBooks(books);
        return book;
    }

    public Book updateBook(Book book) throws IOException {
        List<Book> books = loadBooks();
        for (int i = 0; i < books.size(); i++) {
            if (books.get(i).getId().equals(book.getId())) {
                books.set(i, book);
                saveBooks(books);
                return book;
            }
        }
        throw new IllegalArgumentException("Book not found");
    }

    public void deleteBook(String bookId) throws IOException {
        List<Book> books = loadBooks();
        books.removeIf(b -> b.getId().equals(bookId));
        saveBooks(books);
    }

    public void updateStock(String bookId, int quantity) throws IOException {
        List<Book> books = loadBooks();
        for (Book book : books) {
            if (book.getId().equals(bookId)) {
                book.setStock(book.getStock() - quantity);
                saveBooks(books);
                return;
            }
        }
    }
}
