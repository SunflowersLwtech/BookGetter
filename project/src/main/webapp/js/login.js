document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    hideDisplayError('error-message');

    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const role = document.getElementById('role').value;

    if (!username || !password || !role) {
        displayError('error-message', 'Please fill in all fields');
        return;
    }

    try {
        const response = await fetchAPI('/login', {
            method: 'POST',
            body: JSON.stringify({ username, password, role })
        });

        if (!response.ok) {
            const data = await response.json();
            displayError('error-message', data.message || 'Login failed');
            return;
        }

        const data = await response.json();

        if (data.success && data.user) {
            window.location.href = 'index.html';
        } else {
            displayError('error-message', data.message || 'Login failed');
        }
    } catch (error) {
        console.error('Login error:', error);
        displayError('error-message', error.message || 'An error occurred during login');
    }
});
