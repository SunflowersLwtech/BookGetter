async function loadProfile() {
    const user = await checkAuth();
    if (!user) {
        window.location.href = 'login.html';
        return;
    }

    try {
        const response = await fetchAPI('/user');
        const userData = await response.json();

        document.getElementById('username').value = userData.username;
        document.getElementById('role').value = userData.role;
        document.getElementById('email').value = userData.email || '';
        document.getElementById('phone').value = userData.phone || '';
        document.getElementById('address').value = userData.address || '';
    } catch (error) {
        console.error('Failed to load profile:', error);
    }
}

document.getElementById('profile-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    hideError('error-message');
    hideError('success-message');

    const email = document.getElementById('email').value;
    const phone = document.getElementById('phone').value;
    const address = document.getElementById('address').value;
    const password = document.getElementById('password').value;

    try {
        const response = await fetchAPI('/user', {
            method: 'PUT',
            body: JSON.stringify({ email, phone, address, password })
        });

        const data = await response.json();

        if (data.success) {
            showSuccess('success-message', 'Profile updated successfully!');
            document.getElementById('password').value = '';
        } else {
            showError('error-message', data.message || 'Update failed');
        }
    } catch (error) {
        showError('error-message', error.message || 'Update failed');
    }
});

document.addEventListener('DOMContentLoaded', loadProfile);
