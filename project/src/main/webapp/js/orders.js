async function loadOrders() {
    const user = await checkAuth();
    if (!user) {
        window.location.href = 'login.html';
        return;
    }

    try {
        document.getElementById('loading').style.display = 'block';
        const response = await fetchAPI('/orders');
        const orders = await response.json();

        document.getElementById('loading').style.display = 'none';

        if (orders.length === 0) {
            document.getElementById('no-orders').style.display = 'block';
            return;
        }

        const container = document.getElementById('orders-list');
        container.innerHTML = orders.sort((a, b) => b.createdAt - a.createdAt).map(order => `
            <div class="order-card">
                <div class="order-header">
                    <div>
                        <p class="order-id">Order #${order.id.substring(0, 8)}</p>
                        <p style="color: var(--gray); font-size: 14px;">${formatDate(order.createdAt)}</p>
                    </div>
                    <span class="order-status ${order.status}">${order.status}</span>
                </div>
                <div class="order-items">
                    ${order.items.map(item => `
                        <div class="order-item">
                            <div class="order-item-title">${item.bookTitle}</div>
                            <div class="order-item-details">
                                by ${item.bookAuthor} • Qty: ${item.quantity} • ${formatPrice(item.price)}
                            </div>
                        </div>
                    `).join('')}
                </div>
                <div style="margin-top: 16px;">
                    <p style="font-weight: 600;">Shipping Address:</p>
                    <p style="color: var(--gray); font-size: 14px;">${order.shippingAddress}</p>
                    <p style="color: var(--gray); font-size: 14px;">Phone: ${order.phone}</p>
                </div>
                <div class="order-footer">
                    <span style="font-weight: 600;">Total:</span>
                    <span class="order-total">${formatPrice(order.totalAmount)}</span>
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Failed to load orders:', error);
        document.getElementById('loading').innerHTML = 'Failed to load orders';
    }
}

document.addEventListener('DOMContentLoaded', loadOrders);
