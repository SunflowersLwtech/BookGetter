let cart = null;

async function loadCart() {
    const user = await checkAuth();
    if (!user) {
        window.location.href = 'login.html';
        return;
    }

    try {
        const response = await fetchAPI('/cart');
        cart = await response.json();
        displayCart();
    } catch (error) {
        console.error('Failed to load cart:', error);
        showEmptyCart();
    }
}

function displayCart() {
    if (!cart || cart.items.length === 0) {
        showEmptyCart();
        return;
    }

    document.getElementById('cart-empty').style.display = 'none';
    document.getElementById('cart-content').style.display = 'grid';

    const container = document.getElementById('cart-items');
    container.innerHTML = cart.items.map(item => {
        const stockInfo = item.availableStock !== undefined ?
            `<p class="cart-item-stock">${item.availableStock} available in stock</p>` : '';
        const atStockLimit = item.availableStock !== undefined && item.quantity >= item.availableStock;
        const stockWarning = atStockLimit ?
            `<p class="cart-stock-warning">Maximum quantity reached</p>` : '';

        return `
            <div class="cart-item">
                <img src="${item.imageUrl}" alt="${item.bookTitle}" class="cart-item-image">
                <div class="cart-item-info">
                    <h3 class="cart-item-title">${item.bookTitle}</h3>
                    <p class="cart-item-author">by ${item.bookAuthor}</p>
                    <p class="cart-item-price">${formatPrice(item.price)}</p>
                    ${stockInfo}
                    ${stockWarning}
                    <div class="cart-item-controls">
                        <div class="quantity-control">
                            <button class="quantity-btn" onclick="updateQuantity('${item.bookId}', ${item.quantity - 1})">-</button>
                            <span class="quantity-value">${item.quantity}</span>
                            <button class="quantity-btn" onclick="updateQuantity('${item.bookId}', ${item.quantity + 1})" ${atStockLimit ? 'disabled' : ''}>+</button>
                        </div>
                        <button class="remove-btn" onclick="removeItem('${item.bookId}')">Remove</button>
                    </div>
                </div>
            </div>
        `;
    }).join('');

    updateSummary();
}

function showEmptyCart() {
    document.getElementById('cart-empty').style.display = 'block';
    document.getElementById('cart-content').style.display = 'none';
}

function updateSummary() {
    const total = cart.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    document.getElementById('cart-subtotal').textContent = formatPrice(total);
    document.getElementById('cart-total').textContent = formatPrice(total);
}

async function updateQuantity(bookId, quantity) {
    if (quantity < 1) {
        await showWarning('Quantity must be at least 1. Use Remove button to delete item.');
        return;
    }

    try {
        const response = await fetchAPI('/cart', {
            method: 'PUT',
            body: JSON.stringify({ bookId, quantity })
        });

        const data = await response.json();
        if (data.success) {
            cart = data.cart;
            displayCart();
            updateCartBadge();
        } else if (data.message) {
            await showError(data.message);
        }
    } catch (error) {
        await showError('Failed to update quantity: ' + error.message);
    }
}

async function removeItem(bookId) {
    const confirmed = await showConfirm('Are you sure you want to remove this item from your cart?');
    if (!confirmed) return;

    try {
        const response = await fetchAPI('/cart', {
            method: 'PUT',
            body: JSON.stringify({ bookId, quantity: 0 })
        });

        const data = await response.json();
        if (data.success) {
            cart = data.cart;
            displayCart();
            updateCartBadge();
            await showSuccess('Item removed from cart');
        } else if (data.message) {
            await showError(data.message);
        }
    } catch (error) {
        await showError('Failed to remove item: ' + error.message);
    }
}

async function clearCart() {
    const confirmed = await showConfirm('Are you sure you want to clear your cart?');
    if (!confirmed) return;

    try {
        await fetchAPI('/cart', { method: 'DELETE' });
        cart = { items: [] };
        showEmptyCart();
        updateCartBadge();
        await showSuccess('Cart cleared successfully');
    } catch (error) {
        await showError('Failed to clear cart: ' + error.message);
    }
}

async function useProfileInfo() {
    try {
        const response = await fetchAPI('/user');
        const profile = await response.json();

        if (profile.address) {
            document.getElementById('shipping-address').value = profile.address;
        }
        if (profile.phone) {
            document.getElementById('phone').value = profile.phone;
        }

        if (profile.address || profile.phone) {
            await showSuccess('Profile information loaded successfully');
        } else {
            await showInfo('No address or phone number found in profile. Please update your profile first.');
        }
    } catch (error) {
        await showError('Failed to load profile information: ' + error.message);
    }
}

async function checkout() {
    const address = document.getElementById('shipping-address').value;
    const phone = document.getElementById('phone').value;

    if (!address || !phone) {
        await showWarning('Please fill in shipping address and phone number');
        return;
    }

    try {
        const response = await fetchAPI('/orders', {
            method: 'POST',
            body: JSON.stringify({ shippingAddress: address, phone })
        });

        const data = await response.json();

        if (data.success) {
            await showSuccess('Order placed successfully!');
            window.location.href = 'orders.html';
        } else if (data.message) {
            await showError(data.message);
        }
    } catch (error) {
        await showError('Failed to place order: ' + error.message);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    loadCart();

    document.getElementById('checkout-btn')?.addEventListener('click', checkout);
    document.getElementById('clear-cart-btn')?.addEventListener('click', clearCart);
    document.getElementById('use-profile-btn')?.addEventListener('click', useProfileInfo);
});
