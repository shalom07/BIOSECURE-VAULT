/**
 * BioSecure Data Vault - Application Logic
 * Version: 1.0.0
 * Enterprise Biometric Data Management System
 */

// ============================================
// GLOBAL STATE
// ============================================
const AppState = {
    currentUser: null,
    isAuthenticated: false,
    currentSection: 'overview',
    sessionTimeout: null,
    sessionDuration: 10 * 60 * 1000, // 10 minutes
    loginAttempts: 0,
    maxLoginAttempts: 5,
    biometricEnrolled: {
        iris: false,
        fingerprint: false
    }
};

// ============================================
// AUTHENTICATION FUNCTIONS
// ============================================

function showLogin() {
    hideAllAuthScreens();
    document.getElementById('loginScreen').style.display = 'flex';
    document.getElementById('registerScreen').style.display = 'none';
    document.getElementById('forgotPasswordScreen').style.display = 'none';
    document.getElementById('dashboard').style.display = 'none';
    goToLoginStep(1);
}

function showRegister() {
    hideAllAuthScreens();
    document.getElementById('loginScreen').style.display = 'none';
    document.getElementById('registerScreen').style.display = 'flex';
    document.getElementById('forgotPasswordScreen').style.display = 'none';
    document.getElementById('dashboard').style.display = 'none';
    goToRegStep(1);
}

function showForgotPassword() {
    hideAllAuthScreens();
    document.getElementById('loginScreen').style.display = 'none';
    document.getElementById('registerScreen').style.display = 'none';
    document.getElementById('forgotPasswordScreen').style.display = 'flex';
}

function hideAllAuthScreens() {
    // All auth screens are within authScreens div
}

// Login Step Navigation
function goToLoginStep(step) {
    // Hide all steps
    for (let i = 1; i <= 4; i++) {
        const stepEl = document.getElementById('loginStep' + i);
        if (stepEl) stepEl.style.display = 'none';
    }

    // Show target step
    const targetStep = document.getElementById('loginStep' + step);
    if (targetStep) targetStep.style.display = 'block';

    // Update step indicators
    const steps = document.querySelectorAll('.auth-step');
    steps.forEach((s, idx) => {
        s.classList.remove('active', 'completed');
        if (idx + 1 < step) s.classList.add('completed');
        if (idx + 1 === step) s.classList.add('active');
    });
}

function handleLoginStep1(e) {
    e.preventDefault();
    const username = document.getElementById('loginUsername').value;
    const password = document.getElementById('loginPassword').value;

    if (!username || !password) {
        showToast('Please enter both username and password', 'error');
        return;
    }

    showLoading('Verifying credentials...');

    setTimeout(() => {
        hideLoading();
        // Simulate credential validation
        if (username.length > 0 && password.length > 3) {
            showToast('Credentials verified. Proceeding to biometric authentication.', 'success');
            goToLoginStep(2);
        } else {
            AppState.loginAttempts++;
            showToast('Invalid credentials. Attempt ' + AppState.loginAttempts + ' of ' + AppState.maxLoginAttempts, 'error');
            if (AppState.loginAttempts >= AppState.maxLoginAttempts) {
                showToast('Account locked due to multiple failed attempts. Please contact support.', 'error');
                // In real app: lock account, send email
            }
        }
    }, 1500);
}

function simulateIrisScan() {
    showLoading('Scanning iris pattern... Please keep your eye steady.');

    setTimeout(() => {
        hideLoading();
        showToast('Iris scan successful. Pattern matched.', 'success');
        goToLoginStep(3);
    }, 3000);
}

function simulateFingerprintScan() {
    showLoading('Analyzing fingerprint ridges... Please hold your finger on the scanner.');

    setTimeout(() => {
        hideLoading();
        showToast('Fingerprint verified successfully.', 'success');
        goToLoginStep(4);
    }, 2500);
}

function handle2FAVerification(e) {
    e.preventDefault();
    showLoading('Verifying authentication code...');

    setTimeout(() => {
        hideLoading();
        showToast('Two-factor authentication successful!', 'success');
        completeLogin();
    }, 1500);
}

function useBackupCode() {
    showToast('Backup code verification sent to your registered email.', 'info');
}

function completeLogin() {
    AppState.isAuthenticated = true;
    AppState.currentUser = {
        name: 'John Doe',
        email: 'john.doe@email.com',
        role: 'Standard User',
        initials: 'JD'
    };

    // Hide auth screens, show dashboard
    document.getElementById('authScreens').style.display = 'none';
    document.getElementById('dashboard').style.display = 'block';

    // Update user info in sidebar
    document.getElementById('userName').textContent = AppState.currentUser.name;
    document.getElementById('userRole').textContent = AppState.currentUser.role;
    document.getElementById('userAvatar').textContent = AppState.currentUser.initials;

    showToast('Welcome back, ' + AppState.currentUser.name + '! Your vault is secure.', 'success');

    // Start session timer
    startSessionTimer();

    // Show overview by default
    showSection('overview');
}

function logout() {
    AppState.isAuthenticated = false;
    AppState.currentUser = null;
    clearTimeout(AppState.sessionTimeout);

    document.getElementById('dashboard').style.display = 'none';
    document.getElementById('authScreens').style.display = 'block';
    showLogin();
    showToast('You have been securely logged out.', 'info');
}

// ============================================
// REGISTRATION FUNCTIONS
// ============================================

function goToRegStep(step) {
    // Hide all reg steps
    for (let i = 1; i <= 4; i++) {
        const stepEl = document.getElementById('regStep' + i);
        if (stepEl) stepEl.style.display = 'none';
    }

    // Show target step
    const targetStep = document.getElementById('regStep' + step);
    if (targetStep) targetStep.style.display = 'block';

    // Update progress bar
    const progress = document.getElementById('regProgress');
    if (progress) {
        const percentages = { 1: 25, 2: 50, 3: 75, 4: 100 };
        progress.style.width = percentages[step] + '%';
    }
}

function checkPasswordStrength(password) {
    const strengthBar = document.getElementById('passwordStrength');
    if (!strengthBar) return;

    let strength = 0;
    if (password.length >= 12) strength++;
    if (/[A-Z]/.test(password)) strength++;
    if (/[a-z]/.test(password)) strength++;
    if (/[0-9]/.test(password)) strength++;
    if (/[^A-Za-z0-9]/.test(password)) strength++;

    strengthBar.className = 'password-strength-fill';
    if (strength <= 2) {
        strengthBar.classList.add('strength-weak');
    } else if (strength <= 4) {
        strengthBar.classList.add('strength-medium');
    } else {
        strengthBar.classList.add('strength-strong');
    }
}

function handlePhotoUpload(input) {
    if (input.files && input.files[0]) {
        showToast('Profile photo selected: ' + input.files[0].name, 'success');
    }
}

function simulateEnrollIris() {
    showLoading('Capturing iris pattern... Please look directly at the camera.');

    setTimeout(() => {
        hideLoading();
        AppState.biometricEnrolled.iris = true;
        const statusEl = document.getElementById('irisStatus');
        if (statusEl) {
            statusEl.textContent = 'Enrolled';
            statusEl.style.color = 'var(--success)';
        }
        showToast('Iris pattern enrolled successfully!', 'success');
    }, 3000);
}

function simulateEnrollFingerprint() {
    showLoading('Scanning fingerprint... Please place your finger on the scanner.');

    setTimeout(() => {
        hideLoading();
        AppState.biometricEnrolled.fingerprint = true;
        const statusEl = document.getElementById('fingerprintStatus');
        if (statusEl) {
            statusEl.textContent = 'Enrolled';
            statusEl.style.color = 'var(--success)';
        }
        showToast('Fingerprint enrolled successfully!', 'success');
    }, 2500);
}

function completeRegistration() {
    if (!AppState.biometricEnrolled.iris || !AppState.biometricEnrolled.fingerprint) {
        showToast('Please complete both biometric enrollments before proceeding.', 'warning');
        return;
    }

    showLoading('Creating your secure account...');

    setTimeout(() => {
        hideLoading();
        showToast('Registration complete! Please check your email for verification.', 'success');
        showLogin();
    }, 2000);
}

function handleForgotPassword(e) {
    e.preventDefault();
    showLoading('Sending reset link...');

    setTimeout(() => {
        hideLoading();
        showToast('Password reset link sent to your email address.', 'success');
        showLogin();
    }, 1500);
}

// ============================================
// DASHBOARD NAVIGATION
// ============================================

function showSection(sectionId) {
    // Hide all sections
    const sections = ['overview', 'myData', 'upload', 'activity', 'security', 
                      'profile', 'backup', 'biometrics', 'sessions',
                      'adminUsers', 'adminLogs', 'adminSecurity', 'adminBackup'];

    sections.forEach(s => {
        const el = document.getElementById('section-' + s);
        if (el) el.style.display = 'none';
    });

    // Show target section
    const target = document.getElementById('section-' + sectionId);
    if (target) {
        target.style.display = 'block';
        target.classList.add('fade-in');
    }

    // Update sidebar active state
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });

    // Find and activate the nav item (simplified matching)
    const navMap = {
        'overview': 0, 'myData': 1, 'upload': 2, 'activity': 3,
        'biometrics': 4, 'security': 5, 'sessions': 6,
        'profile': 7, 'backup': 8,
        'adminUsers': 9, 'adminLogs': 10, 'adminSecurity': 11, 'adminBackup': 12
    };

    const navItems = document.querySelectorAll('.nav-item');
    if (navMap[sectionId] !== undefined && navItems[navMap[sectionId]]) {
        navItems[navMap[sectionId]].classList.add('active');
    }

    AppState.currentSection = sectionId;

    // Close mobile sidebar
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');
    if (sidebar) sidebar.classList.remove('open');
    if (overlay) overlay.classList.remove('active');
}

function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');

    if (sidebar) {
        sidebar.classList.toggle('open');
    }
    if (overlay) {
        overlay.classList.toggle('active');
    }
}

// ============================================
// DATA MANAGEMENT
// ============================================

function handleUpload(e) {
    e.preventDefault();
    showLoading('Encrypting and uploading your data...');

    setTimeout(() => {
        hideLoading();
        showToast('Data uploaded and encrypted successfully!', 'success');
        showSection('myData');
    }, 2500);
}

function handleFileSelect(input) {
    if (input.files && input.files[0]) {
        const file = input.files[0];
        const preview = document.getElementById('filePreview');
        const nameEl = document.getElementById('fileName');
        const sizeEl = document.getElementById('fileSize');

        if (preview) preview.style.display = 'block';
        if (nameEl) nameEl.textContent = file.name;
        if (sizeEl) sizeEl.textContent = formatFileSize(file.size);
    }
}

function clearFile() {
    const input = document.getElementById('uploadFile');
    const preview = document.getElementById('filePreview');
    if (input) input.value = '';
    if (preview) preview.style.display = 'none';
}

function handleDragOver(e) {
    e.preventDefault();
    e.currentTarget.classList.add('dragover');
}

function handleDragLeave(e) {
    e.currentTarget.classList.remove('dragover');
}

function handleDrop(e) {
    e.preventDefault();
    e.currentTarget.classList.remove('dragover');

    const files = e.dataTransfer.files;
    if (files.length > 0) {
        const input = document.getElementById('uploadFile');
        const dt = new DataTransfer();
        dt.items.add(files[0]);
        input.files = dt.files;
        handleFileSelect(input);
    }
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// ============================================
// EXPORT & BACKUP
// ============================================

function exportData() {
    showToast('Preparing data export...', 'info');
    setTimeout(() => {
        showToast('Data export ready! Download started.', 'success');
    }, 1500);
}

function exportToPDF() {
    showLoading('Generating PDF export...');
    setTimeout(() => {
        hideLoading();
        showToast('PDF export completed!', 'success');
    }, 2000);
}

function exportToExcel() {
    showLoading('Generating Excel export...');
    setTimeout(() => {
        hideLoading();
        showToast('Excel export completed!', 'success');
    }, 2000);
}

function exportToJSON() {
    showLoading('Generating JSON export...');
    setTimeout(() => {
        hideLoading();
        showToast('JSON export completed!', 'success');
    }, 1500);
}

function exportToCSV() {
    showLoading('Generating CSV export...');
    setTimeout(() => {
        hideLoading();
        showToast('CSV export completed!', 'success');
    }, 1500);
}

function createBackup() {
    showLoading('Creating encrypted backup...');
    setTimeout(() => {
        hideLoading();
        showToast('Encrypted backup created successfully!', 'success');
    }, 3000);
}

function createSystemBackup() {
    showLoading('Creating system-wide backup... This may take a few minutes.');
    setTimeout(() => {
        hideLoading();
        showToast('System backup completed and verified!', 'success');
    }, 4000);
}

// ============================================
// SECURITY FUNCTIONS
// ============================================

function handlePasswordChange(e) {
    e.preventDefault();
    showLoading('Updating password...');
    setTimeout(() => {
        hideLoading();
        showToast('Password updated successfully!', 'success');
        e.target.reset();
    }, 1500);
}

function handleProfileUpdate(e) {
    e.preventDefault();
    showLoading('Saving profile changes...');
    setTimeout(() => {
        hideLoading();
        showToast('Profile updated successfully!', 'success');
    }, 1500);
}

function terminateSession(btn) {
    if (confirm('Are you sure you want to terminate this session?')) {
        btn.closest('.d-flex').remove();
        showToast('Session terminated successfully.', 'success');
    }
}

function terminateAllSessions() {
    if (confirm('Terminate all other sessions? You will remain logged in on this device.')) {
        showToast('All other sessions have been terminated.', 'success');
        // Remove all non-current sessions
        document.querySelectorAll('#section-sessions .glass-panel .d-flex').forEach((el, idx) => {
            if (idx > 0) el.remove();
        });
    }
}

// ============================================
// SESSION MANAGEMENT
// ============================================

function startSessionTimer() {
    clearTimeout(AppState.sessionTimeout);
    AppState.sessionTimeout = setTimeout(() => {
        showToast('Session expired due to inactivity. Please log in again.', 'warning');
        logout();
    }, AppState.sessionDuration);
}

function resetSessionTimer() {
    if (AppState.isAuthenticated) {
        startSessionTimer();
    }
}

// Reset timer on user activity
document.addEventListener('click', resetSessionTimer);
document.addEventListener('keypress', resetSessionTimer);
document.addEventListener('scroll', resetSessionTimer);

// ============================================
// UI UTILITIES
// ============================================

function showLoading(text) {
    const overlay = document.getElementById('loadingOverlay');
    const textEl = document.getElementById('loadingText');
    if (overlay) overlay.style.display = 'flex';
    if (textEl && text) textEl.textContent = text;
}

function hideLoading() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) overlay.style.display = 'none';
}

function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = 'toast toast-' + type;

    const icons = {
        success: 'fa-check-circle',
        error: 'fa-times-circle',
        warning: 'fa-exclamation-triangle',
        info: 'fa-info-circle'
    };

    toast.innerHTML = '<i class="fas ' + icons[type] + '"></i><span>' + message + '</span>';
    container.appendChild(toast);

    // Auto remove after 4 seconds
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(100%)';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

function moveToNext(input, index) {
    if (input.value.length === 1) {
        const inputs = input.parentElement.querySelectorAll('input');
        if (inputs[index + 1]) {
            inputs[index + 1].focus();
        }
    }
}

function showNotifications() {
    showToast('You have 2 new security notifications.', 'info');
}

function toggleTheme() {
    showToast('Theme toggle feature coming soon!', 'info');
}

// ============================================
// ADMIN FUNCTIONS
// ============================================

function toggleAdminMode() {
    const adminNav = document.getElementById('adminNav');
    if (adminNav) {
        adminNav.style.display = adminNav.style.display === 'none' ? 'block' : 'none';
    }
}

// ============================================
// INITIALIZATION
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    // Initialize app
    console.log('BioSecure Data Vault initialized');
    console.log('Version: 1.0.0');
    console.log('Security: AES-256 | bcrypt | WebAuthn Ready');

    // Check for saved session (simulated)
    // In production: validate JWT token here

    // Setup drag and drop for upload zone
    const dropZone = document.getElementById('dropZone');
    if (dropZone) {
        dropZone.addEventListener('dragover', handleDragOver);
        dropZone.addEventListener('dragleave', handleDragLeave);
        dropZone.addEventListener('drop', handleDrop);
    }

    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        // ESC to close modals or sidebar
        if (e.key === 'Escape') {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.getElementById('sidebarOverlay');
            if (sidebar && sidebar.classList.contains('open')) {
                sidebar.classList.remove('open');
                overlay.classList.remove('active');
            }
        }
    });
});

// Security: Prevent right-click context menu in production
// document.addEventListener('contextmenu', e => e.preventDefault());

// Security: Prevent dev tools shortcuts in production
// document.addEventListener('keydown', e => {
//     if (e.key === 'F12' || (e.ctrlKey && e.shiftKey && e.key === 'I')) {
//         e.preventDefault();
//     }
// });
