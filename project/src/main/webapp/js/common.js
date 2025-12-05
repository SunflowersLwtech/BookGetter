const API_BASE = '/BookGetter/api';

async function fetchAPI(url, options = {}) {
    try {
        const response = await fetch(API_BASE + url, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        });

        if (!response.ok && response.status !== 401 && response.status !== 403) {
            const error = await response.json();
            throw new Error(error.message || 'Request failed');
        }

        return response;
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

async function checkAuth() {
    try {
        const response = await fetchAPI('/login');
        const data = await response.json();

        const navUser = document.getElementById('nav-user');
        const navGuest = document.getElementById('nav-guest');
        const adminLink = document.getElementById('admin-link');
        const cartLink = document.getElementById('cart-link');
        const ordersLinks = document.querySelectorAll('a[href="orders.html"]');

        if (data.loggedIn) {
            if (navUser) navUser.style.display = 'flex';
            if (navGuest) navGuest.style.display = 'none';

            if (data.user.role === 'admin') {
                if (adminLink) adminLink.style.display = 'block';
                if (cartLink) cartLink.style.display = 'none';
                ordersLinks.forEach(link => link.style.display = 'none');
            } else {
                if (adminLink) adminLink.style.display = 'none';
                if (cartLink) cartLink.style.display = 'block';
                updateCartBadge();
            }

            const logoutBtn = document.getElementById('logout-btn');
            if (logoutBtn) {
                logoutBtn.onclick = logout;
            }

            return data.user;
        } else {
            if (navUser) navUser.style.display = 'none';
            if (navGuest) navGuest.style.display = 'flex';
            return null;
        }
    } catch (error) {
        console.error('Auth check failed:', error);
        return null;
    }
}

async function logout() {
    try {
        await fetchAPI('/login', { method: 'DELETE' });
        window.location.href = 'index.html';
    } catch (error) {
        console.error('Logout failed:', error);
    }
}

async function updateCartBadge() {
    try {
        const response = await fetchAPI('/cart');
        if (response.ok) {
            const cart = await response.json();
            const badge = document.getElementById('cart-badge');
            if (badge) {
                const itemCount = cart.items.reduce((sum, item) => sum + item.quantity, 0);
                badge.textContent = itemCount;
            }
        }
    } catch (error) {
        console.error('Failed to update cart badge:', error);
    }
}

function formatPrice(price) {
    return `RM ${price.toFixed(2)}`;
}

function formatDate(timestamp) {
    return new Date(timestamp).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

function displayError(elementId, message) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = message;
        element.style.display = 'block';
    }
}

function hideDisplayError(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.style.display = 'none';
    }
}

function displaySuccess(elementId, message) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = message;
        element.style.display = 'block';
    }
}

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
});
