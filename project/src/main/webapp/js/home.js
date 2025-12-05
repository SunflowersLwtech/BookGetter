async function loadPopularBooks() {
    try {
        const response = await fetchAPI('/books');
        const books = await response.json();

        const popularBooks = books.slice(0, 8);
        const container = document.getElementById('popular-books');

        container.innerHTML = popularBooks.map(book => `
            <div class="book-card">
                <img src="${book.imageUrl}" alt="${book.title}" class="book-image">
                <div class="book-info">
                    <h3 class="book-title">${book.title}</h3>
                    <p class="book-author">by ${book.author}</p>
                    <span class="book-category">${book.category}</span>
                    <p class="book-price">${formatPrice(book.price)}</p>
                    <p class="book-stock">${book.stock} in stock</p>
                    <button class="btn btn-primary btn-block" onclick="viewBook('${book.id}')">
                        View Details
                    </button>
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Failed to load books:', error);
    }
}

function viewBook(bookId) {
    window.location.href = `books.html?id=${bookId}`;
}

document.addEventListener('DOMContentLoaded', () => {
    loadPopularBooks();
});
