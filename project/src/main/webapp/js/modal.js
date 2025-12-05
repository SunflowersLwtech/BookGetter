function showModal(message, type = 'info', title = '') {
    return new Promise((resolve) => {
        const existingModal = document.getElementById('alert-modal');
        if (existingModal) {
            existingModal.remove();
        }

        const icons = {
            success: '✓',
            error: '✕',
            warning: '⚠',
            info: 'ℹ'
        };

        const titles = {
            success: title || 'Success',
            error: title || 'Error',
            warning: title || 'Warning',
            info: title || 'Information'
        };

        const modal = document.createElement('div');
        modal.id = 'alert-modal';
        modal.className = 'alert-modal';
        modal.innerHTML = `
            <div class="alert-modal-content">
                <div class="alert-modal-header">
                    <div class="alert-modal-icon ${type}">${icons[type] || icons.info}</div>
                    <div class="alert-modal-title">${titles[type]}</div>
                </div>
                <div class="alert-modal-message">${message}</div>
                <div class="alert-modal-actions">
                    <button class="alert-modal-btn primary" id="alert-modal-ok">OK</button>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        const okBtn = document.getElementById('alert-modal-ok');

        const closeModal = () => {
            modal.style.opacity = '0';
            setTimeout(() => {
                modal.remove();
                resolve();
            }, 200);
        };

        okBtn.onclick = closeModal;
        modal.onclick = (e) => {
            if (e.target === modal) {
                closeModal();
            }
        };

        document.addEventListener('keydown', function escHandler(e) {
            if (e.key === 'Escape') {
                closeModal();
                document.removeEventListener('keydown', escHandler);
            }
        });
    });
}

function showConfirm(message, title = 'Confirm') {
    return new Promise((resolve) => {
        const existingModal = document.getElementById('alert-modal');
        if (existingModal) {
            existingModal.remove();
        }

        const modal = document.createElement('div');
        modal.id = 'alert-modal';
        modal.className = 'alert-modal';
        modal.innerHTML = `
            <div class="alert-modal-content">
                <div class="alert-modal-header">
                    <div class="alert-modal-icon warning">?</div>
                    <div class="alert-modal-title">${title}</div>
                </div>
                <div class="alert-modal-message">${message}</div>
                <div class="alert-modal-actions">
                    <button class="alert-modal-btn secondary" id="alert-modal-cancel">Cancel</button>
                    <button class="alert-modal-btn primary" id="alert-modal-confirm">Confirm</button>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        const confirmBtn = document.getElementById('alert-modal-confirm');
        const cancelBtn = document.getElementById('alert-modal-cancel');

        const closeModal = (result) => {
            modal.style.opacity = '0';
            setTimeout(() => {
                modal.remove();
                resolve(result);
            }, 200);
        };

        confirmBtn.onclick = () => closeModal(true);
        cancelBtn.onclick = () => closeModal(false);
        modal.onclick = (e) => {
            if (e.target === modal) {
                closeModal(false);
            }
        };

        document.addEventListener('keydown', function escHandler(e) {
            if (e.key === 'Escape') {
                closeModal(false);
                document.removeEventListener('keydown', escHandler);
            }
        });
    });
}

function showSuccess(message, title) {
    return showModal(message, 'success', title);
}

function showError(message, title) {
    return showModal(message, 'error', title);
}

function showWarning(message, title) {
    return showModal(message, 'warning', title);
}

function showInfo(message, title) {
    return showModal(message, 'info', title);
}
