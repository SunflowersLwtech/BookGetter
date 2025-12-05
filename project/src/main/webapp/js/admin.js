let currentTab = 'stats';

async function checkAdminAccess() {
    const user = await checkAuth();
    if (!user || user.role !== 'admin') {
        await showError('Admin access required');
        window.location.href = 'index.html';
        return false;
    }
    return true;
}

async function loadStats() {
    try {
        const response = await fetchAPI('/admin/stats');
        const stats = await response.json();

        document.getElementById('stat-books').textContent = stats.totalBooks;
        document.getElementById('stat-orders').textContent = stats.totalOrders;
        document.getElementById('stat-customers').textContent = stats.totalCustomers;
        document.getElementById('stat-revenue').textContent = formatPrice(stats.totalRevenue);
    } catch (error) {
        console.error('Failed to load stats:', error);
    }
}

async function loadAdminBooks() {
    try {
        const response = await fetchAPI('/admin/books');
        const books = await response.json();

        const container = document.getElementById('books-list');
        container.innerHTML = books.map(book => `
            <div class="admin-item">
                <div class="admin-item-info">
                    <h4>${book.title}</h4>
                    <p>by ${book.author} • ${book.category} • ${formatPrice(book.price)} • Stock: ${book.stock}</p>
                </div>
                <div class="admin-item-actions">
                    <button class="btn btn-primary btn-sm" onclick="editBook('${book.id}')">Edit</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteBook('${book.id}')">Delete</button>
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Failed to load books:', error);
    }
}

async function loadAdminOrders() {
    try {
        const response = await fetchAPI('/admin/orders');
        const orders = await response.json();

        const container = document.getElementById('orders-list');
        container.innerHTML = orders.sort((a, b) => b.createdAt - a.createdAt).map(order => `
            <div class="admin-item">
                <div class="admin-item-info">
                    <h4>Order #${order.id.substring(0, 8)}</h4>
                    <p>${formatDate(order.createdAt)} • ${formatPrice(order.totalAmount)} • Status: ${order.status}</p>
                    <p style="font-size: 12px; margin-top: 4px;">
                        ${order.items.length} item(s) • ${order.shippingAddress}
                    </p>
                </div>
                <div class="admin-item-actions">
                    <select onchange="updateOrderStatus('${order.id}', this.value)" style="padding: 6px 12px; border-radius: 6px;">
                        <option value="pending" ${order.status === 'pending' ? 'selected' : ''}>Pending</option>
                        <option value="shipped" ${order.status === 'shipped' ? 'selected' : ''}>Shipped</option>
                        <option value="completed" ${order.status === 'completed' ? 'selected' : ''}>Completed</option>
                    </select>
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Failed to load orders:', error);
    }
}

async function loadAdminUsers() {
    try {
        const response = await fetchAPI('/admin/users');
        const users = await response.json();

        const container = document.getElementById('users-list');
        container.innerHTML = users.map(user => `
            <div class="admin-item">
                <div class="admin-item-info">
                    <h4>${user.username}</h4>
                    <p>${user.email} • Role: ${user.role} • Joined: ${formatDate(user.createdAt)}</p>
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Failed to load users:', error);
    }
}

function switchTab(tab) {
    currentTab = tab;

    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });

    document.querySelector(`[data-tab="${tab}"]`).classList.add('active');
    document.getElementById(`${tab}-tab`).classList.add('active');

    if (tab === 'stats') loadStats();
    else if (tab === 'books') loadAdminBooks();
    else if (tab === 'orders') loadAdminOrders();
    else if (tab === 'users') loadAdminUsers();
}

function showBookModal(book = null) {
    const modal = document.getElementById('book-modal');
    const form = document.getElementById('book-form');
    const previewContainer = document.getElementById('image-preview-container');
    const preview = document.getElementById('image-preview');

    if (book) {
        document.getElementById('modal-title').textContent = 'Edit Book';
        document.getElementById('book-id').value = book.id;
        document.getElementById('book-title').value = book.title;
        document.getElementById('book-author').value = book.author;
        document.getElementById('book-isbn').value = book.isbn;
        document.getElementById('book-price').value = book.price;
        document.getElementById('book-stock').value = book.stock;
        document.getElementById('book-category').value = book.category;
        document.getElementById('book-image').value = book.imageUrl;
        document.getElementById('book-description').value = book.description;

        if (book.imageUrl) {
            preview.src = book.imageUrl;
            previewContainer.style.display = 'block';
        }
    } else {
        document.getElementById('modal-title').textContent = 'Add Book';
        form.reset();
        document.getElementById('book-image').value = '';
        previewContainer.style.display = 'none';
    }

    modal.style.display = 'flex';
}

function closeBookModal() {
    document.getElementById('book-modal').style.display = 'none';
}

async function editBook(bookId) {
    try {
        const response = await fetchAPI(`/books?id=${bookId}`);
        const book = await response.json();
        showBookModal(book);
    } catch (error) {
        await showError('Failed to load book: ' + error.message);
    }
}

async function deleteBook(bookId) {
    const confirmed = await showConfirm('Are you sure you want to delete this book?');
    if (!confirmed) return;

    try {
        await fetchAPI(`/admin/books/${bookId}`, { method: 'DELETE' });
        await showSuccess('Book deleted successfully');
        loadAdminBooks();
    } catch (error) {
        await showError('Failed to delete book: ' + error.message);
    }
}

async function updateOrderStatus(orderId, status) {
    try {
        await fetchAPI(`/admin/orders/${orderId}`, {
            method: 'PUT',
            body: JSON.stringify({ status })
        });
        await showSuccess('Order status updated successfully');
        loadAdminOrders();
    } catch (error) {
        await showError('Failed to update order status: ' + error.message);
    }
}

async function uploadImage() {
    const fileInput = document.getElementById('book-image-file');
    const file = fileInput.files[0];

    if (!file) {
        await showWarning('Please select an image file first');
        return;
    }

    if (!file.type.startsWith('image/')) {
        await showError('Please select a valid image file');
        return;
    }

    try {
        const formData = new FormData();
        formData.append('image', file);

        const response = await fetch(API_BASE + '/upload', {
            method: 'POST',
            body: formData,
            credentials: 'include'
        });

        const result = await response.json();

        if (!result.success) {
            throw new Error(result.message || 'Upload failed');
        }

        const imageUrl = result.imageUrl;

        document.getElementById('book-image').value = imageUrl;
        const preview = document.getElementById('image-preview');
        const previewContainer = document.getElementById('image-preview-container');
        preview.src = imageUrl;
        previewContainer.style.display = 'block';
        await showSuccess('Image uploaded successfully');
    } catch (error) {
        await showError('Failed to upload image: ' + error.message);
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    if (!await checkAdminAccess()) return;

    loadStats();

    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => switchTab(btn.dataset.tab));
    });

    document.getElementById('add-book-btn').addEventListener('click', () => showBookModal());

    document.querySelector('.modal-close').addEventListener('click', closeBookModal);

    document.getElementById('upload-image-btn').addEventListener('click', uploadImage);

    document.getElementById('book-form').addEventListener('submit', async (e) => {
        e.preventDefault();

        const bookId = document.getElementById('book-id').value;
        const imageUrl = document.getElementById('book-image').value;

        if (!imageUrl) {
            await showWarning('Please upload a book cover image');
            return;
        }

        const bookData = {
            title: document.getElementById('book-title').value,
            author: document.getElementById('book-author').value,
            isbn: document.getElementById('book-isbn').value,
            price: parseFloat(document.getElementById('book-price').value),
            stock: parseInt(document.getElementById('book-stock').value),
            category: document.getElementById('book-category').value,
            imageUrl: imageUrl,
            description: document.getElementById('book-description').value
        };

        try {
            if (bookId) {
                bookData.id = bookId;
                await fetchAPI(`/admin/books/${bookId}`, {
                    method: 'PUT',
                    body: JSON.stringify(bookData)
                });
                await showSuccess('Book updated successfully');
            } else {
                await fetchAPI('/admin/books', {
                    method: 'POST',
                    body: JSON.stringify(bookData)
                });
                await showSuccess('Book added successfully');
            }

            closeBookModal();
            loadAdminBooks();
        } catch (error) {
            await showError('Failed to save book: ' + error.message);
        }
    });
});
