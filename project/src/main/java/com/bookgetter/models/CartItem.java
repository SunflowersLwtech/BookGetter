package com.bookgetter.models;

public class CartItem {
    private String bookId;
    private String bookTitle;
    private String bookAuthor;
    private double price;
    private int quantity;
    private String imageUrl;
    private int availableStock;

    public CartItem() {}

    public CartItem(String bookId, String bookTitle, String bookAuthor,
                    double price, int quantity, String imageUrl) {
        this.bookId = bookId;
        this.bookTitle = bookTitle;
        this.bookAuthor = bookAuthor;
        this.price = price;
        this.quantity = quantity;
        this.imageUrl = imageUrl;
    }

    public CartItem(String bookId, String bookTitle, String bookAuthor,
                    double price, int quantity, String imageUrl, int availableStock) {
        this.bookId = bookId;
        this.bookTitle = bookTitle;
        this.bookAuthor = bookAuthor;
        this.price = price;
        this.quantity = quantity;
        this.imageUrl = imageUrl;
        this.availableStock = availableStock;
    }

    public String getBookId() { return bookId; }
    public void setBookId(String bookId) { this.bookId = bookId; }

    public String getBookTitle() { return bookTitle; }
    public void setBookTitle(String bookTitle) { this.bookTitle = bookTitle; }

    public String getBookAuthor() { return bookAuthor; }
    public void setBookAuthor(String bookAuthor) { this.bookAuthor = bookAuthor; }

    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public int getAvailableStock() { return availableStock; }
    public void setAvailableStock(int availableStock) { this.availableStock = availableStock; }

    public double getSubtotal() {
        return price * quantity;
    }
}
