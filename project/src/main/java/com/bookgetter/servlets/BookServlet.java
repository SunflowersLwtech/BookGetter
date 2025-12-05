package com.bookgetter.servlets;

import com.bookgetter.models.Book;
import com.bookgetter.services.BookService;
import com.bookgetter.utils.JsonUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/api/books")
public class BookServlet extends HttpServlet {
    private BookService bookService = BookService.getInstance();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            String bookId = request.getParameter("id");
            String search = request.getParameter("search");
            String category = request.getParameter("category");

            if (bookId != null) {
                Book book = bookService.getBookById(bookId);
                if (book != null) {
                    response.getWriter().write(JsonUtil.toJson(book));
                } else {
                    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    Map<String, Object> result = new HashMap<>();
                    result.put("success", false);
                    result.put("message", "Book not found");
                    response.getWriter().write(JsonUtil.toJson(result));
                }
            } else if (search != null && !search.isEmpty()) {
                List<Book> books = bookService.searchBooks(search);
                response.getWriter().write(JsonUtil.toJson(books));
            } else if (category != null && !category.isEmpty()) {
                List<Book> books = bookService.getBooksByCategory(category);
                response.getWriter().write(JsonUtil.toJson(books));
            } else {
                List<Book> books = bookService.getAllBooks();
                response.getWriter().write(JsonUtil.toJson(books));
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
