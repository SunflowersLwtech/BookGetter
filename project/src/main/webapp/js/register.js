document.getElementById('register-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    hideDisplayError('error-message');

    const username = document.getElementById('username').value;
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    if (password.length < 6) {
        displayError('error-message', 'Password must be at least 6 characters long');
        return;
    }

    try {
        const response = await fetchAPI('/register', {
            method: 'POST',
            body: JSON.stringify({ username, email, password, role: 'customer' })
        });

        const data = await response.json();

        if (data.success) {
            await showSuccess('Registration successful! Welcome to BookGetter.');
            window.location.href = 'login.html';
        } else {
            displayError('error-message', data.message || 'Registration failed');
        }
    } catch (error) {
        displayError('error-message', error.message || 'Registration failed');
    }
});
