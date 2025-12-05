let allBooks = [];
let filteredBooks = [];
let currentUser = null;

async function loadBooks() {
    try {
        document.getElementById('loading').style.display = 'block';
        currentUser = await checkAuth();
        const response = await fetchAPI('/books');
        allBooks = await response.json();
        filteredBooks = allBooks;
        displayBooks(filteredBooks);
        document.getElementById('loading').style.display = 'none';
    } catch (error) {
        console.error('Failed to load books:', error);
        document.getElementById('loading').innerHTML = 'Failed to load books';
    }
}

function displayBooks(books) {
    const container = document.getElementById('books-grid');
    const noResults = document.getElementById('no-results');

    if (books.length === 0) {
        container.innerHTML = '';
        noResults.style.display = 'block';
        return;
    }

    const isAdmin = currentUser && currentUser.role === 'admin';

    noResults.style.display = 'none';
    container.innerHTML = books.map(book => `
        <div class="book-card">
            <img src="${book.imageUrl}" alt="${book.title}" class="book-image" onerror="this.src='https://via.placeholder.com/300x450?text=No+Image'">
            <div class="book-info">
                <h3 class="book-title">${book.title}</h3>
                <p class="book-author">by ${book.author}</p>
                <span class="book-category">${book.category}</span>
                <p class="book-price">${formatPrice(book.price)}</p>
                <p class="book-stock">${book.stock > 0 ? `${book.stock} in stock` : 'Out of stock'}</p>
                ${!isAdmin ? `
                <button class="btn btn-primary btn-block"
                    onclick="addToCart('${book.id}')"
                    ${book.stock === 0 ? 'disabled' : ''}>
                    Add to Cart
                </button>
                ` : ''}
            </div>
        </div>
    `).join('');
}

async function addToCart(bookId) {
    const user = await checkAuth();
    if (!user) {
        await showWarning('Please login to add items to cart');
        window.location.href = 'login.html';
        return;
    }

    try {
        const response = await fetchAPI('/cart', {
            method: 'POST',
            body: JSON.stringify({ bookId, quantity: 1 })
        });

        const data = await response.json();

        if (data.success) {
            updateCartBadge();
            await showSuccess('Book added to cart!');
        } else if (data.message) {
            await showError(data.message);
        }
    } catch (error) {
        await showError('Failed to add to cart: ' + error.message);
    }
}

function filterByCategory(category, buttonElement) {
    if (category === 'all') {
        filteredBooks = allBooks;
    } else {
        filteredBooks = allBooks.filter(book => book.category === category);
    }
    displayBooks(filteredBooks);

    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    if (buttonElement) {
        buttonElement.classList.add('active');
    }
}

function searchBooks() {
    const query = document.getElementById('search-input').value.toLowerCase();
    if (!query) {
        filteredBooks = allBooks;
    } else {
        filteredBooks = allBooks.filter(book =>
            book.title.toLowerCase().includes(query) ||
            book.author.toLowerCase().includes(query) ||
            book.category.toLowerCase().includes(query)
        );
    }
    displayBooks(filteredBooks);
}

document.addEventListener('DOMContentLoaded', () => {
    loadBooks();

    document.getElementById('search-btn').addEventListener('click', searchBooks);
    document.getElementById('search-input').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            searchBooks();
        }
    });

    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            filterByCategory(btn.dataset.category, btn);
        });
    });
});
