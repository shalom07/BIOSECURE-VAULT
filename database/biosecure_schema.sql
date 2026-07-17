-- ============================================================
-- BioSecure Data Vault - Enterprise Database Schema
-- Version: 1.0.0
-- Database: MySQL 8.0+
-- Security: AES-256 Encryption, bcrypt Hashing, RBAC
-- ============================================================

-- Drop existing database if exists (Caution: Production use)
-- DROP DATABASE IF EXISTS biosecure_vault;

-- Create Database
CREATE DATABASE IF NOT EXISTS biosecure_vault 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE biosecure_vault;

-- ============================================================
-- TABLE: Roles (RBAC Foundation)
-- ============================================================
CREATE TABLE roles (
    role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    permissions JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role_name (role_name)
) ENGINE=InnoDB;

-- Insert Default Roles
INSERT INTO roles (role_name, role_description, permissions) VALUES
('super_admin', 'Full system access and control', 
 '{"users":"full","biometrics":"full","data":"full","logs":"full","system":"full","backup":"full"}'),
('admin', 'Administrative access with limited system controls', 
 '{"users":"manage","biometrics":"view","data":"full","logs":"view","system":"view","backup":"manage"}'),
('security_officer', 'Security monitoring and audit access', 
 '{"users":"view","biometrics":"view","data":"view","logs":"full","system":"view","backup":"view"}'),
('user', 'Standard user access to own data only', 
 '{"users":"self","biometrics":"self","data":"self","logs":"self","system":"none","backup":"none"}');

-- ============================================================
-- TABLE: Users
-- ============================================================
CREATE TABLE users (
    user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id INT UNSIGNED NOT NULL DEFAULT 4,
    full_name VARCHAR(255) NOT NULL,
    national_id VARCHAR(100) NOT NULL UNIQUE,
    date_of_birth DATE NOT NULL,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say') NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    profile_photo VARCHAR(500),
    email_verified_at TIMESTAMP NULL,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    two_factor_recovery_codes TEXT,
    account_status ENUM('active', 'locked', 'suspended', 'pending') DEFAULT 'pending',
    failed_login_attempts INT UNSIGNED DEFAULT 0,
    locked_until TIMESTAMP NULL,
    last_login_at TIMESTAMP NULL,
    last_login_ip VARCHAR(45),
    session_token VARCHAR(255),
    session_expires_at TIMESTAMP NULL,
    encryption_key_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,

    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE RESTRICT,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_national_id (national_id),
    INDEX idx_status (account_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: Biometrics (Secure Template Storage)
-- ============================================================
CREATE TABLE biometrics (
    biometric_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    fingerprint_template BLOB NOT NULL,
    fingerprint_template_hash VARCHAR(255) NOT NULL,
    iris_template BLOB NOT NULL,
    iris_template_hash VARCHAR(255) NOT NULL,
    biometric_public_key TEXT,
    credential_id VARCHAR(255),
    webauthn_data JSON,
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_verified_at TIMESTAMP NULL,
    verification_count INT UNSIGNED DEFAULT 0,
    template_version INT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_biometric (user_id),
    INDEX idx_fingerprint_hash (fingerprint_template_hash),
    INDEX idx_iris_hash (iris_template_hash)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: Login Logs (Audit Trail)
-- ============================================================
CREATE TABLE login_logs (
    log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED,
    username_attempted VARCHAR(100),
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP NULL,
    authentication_method ENUM('iris', 'fingerprint', 'password', '2fa', 'webauthn', 'backup_code') NOT NULL,
    auth_step ENUM('step_1_username', 'step_2_iris', 'step_3_fingerprint', 'step_4_2fa', 'step_5_complete') NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    device_fingerprint VARCHAR(255),
    geolocation JSON,
    status ENUM('success', 'failed', 'locked', 'timeout', 'error') NOT NULL,
    failure_reason VARCHAR(255),
    session_id VARCHAR(255),
    risk_score DECIMAL(3,2) DEFAULT 0.00,
    is_suspicious BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_login_time (login_time),
    INDEX idx_ip_address (ip_address),
    INDEX idx_status (status),
    INDEX idx_suspicious (is_suspicious)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: User Data (Encrypted Personal Data)
-- ============================================================
CREATE TABLE user_data (
    data_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    data_title VARCHAR(255) NOT NULL,
    data_description TEXT,
    data_category ENUM('personal', 'financial', 'medical', 'legal', 'employment', 'education', 'other') NOT NULL,
    data_content LONGTEXT NOT NULL,
    data_content_encrypted BOOLEAN DEFAULT TRUE,
    encryption_iv VARCHAR(255),
    file_path VARCHAR(500),
    file_size BIGINT UNSIGNED,
    file_mime_type VARCHAR(100),
    checksum VARCHAR(255),
    is_favorite BOOLEAN DEFAULT FALSE,
    access_count INT UNSIGNED DEFAULT 0,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP NULL,
    created_by INT UNSIGNED,
    modified_by INT UNSIGNED,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (modified_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_category (data_category),
    INDEX idx_upload_date (upload_date),
    FULLTEXT INDEX ft_title_desc (data_title, data_description)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: Data Access Logs
-- ============================================================
CREATE TABLE data_access_logs (
    access_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    data_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    access_type ENUM('view', 'download', 'edit', 'delete', 'share') NOT NULL,
    access_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,

    FOREIGN KEY (data_id) REFERENCES user_data(data_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_data_id (data_id),
    INDEX idx_access_time (access_time)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: Security Events
-- ============================================================
CREATE TABLE security_events (
    event_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_type ENUM('failed_login', 'account_lock', 'password_change', 'biometric_enrollment', 
                    'data_breach_attempt', 'privilege_escalation', 'session_hijack_attempt',
                    'unusual_access_pattern', 'backup_created', 'encryption_rotation') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    user_id INT UNSIGNED,
    description TEXT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSON,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by INT UNSIGNED,
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (resolved_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_event_type (event_type),
    INDEX idx_severity (severity),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: Backup Records
-- ============================================================
CREATE TABLE backup_records (
    backup_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    backup_name VARCHAR(255) NOT NULL,
    backup_type ENUM('full', 'incremental', 'differential') NOT NULL,
    backup_path VARCHAR(500) NOT NULL,
    backup_size BIGINT UNSIGNED,
    checksum VARCHAR(255),
    encryption_status BOOLEAN DEFAULT TRUE,
    created_by INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    status ENUM('running', 'completed', 'failed', 'verified') DEFAULT 'running',

    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE RESTRICT,
    INDEX idx_backup_type (backup_type),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: Password Resets
-- ============================================================
CREATE TABLE password_resets (
    reset_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_token (token_hash),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: Email Verifications
-- ============================================================
CREATE TABLE email_verifications (
    verification_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    verified_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_token (token_hash)
) ENGINE=InnoDB;

-- ============================================================
-- VIEWS FOR REPORTING
-- ============================================================

-- Active Users View
CREATE VIEW vw_active_users AS
SELECT u.*, r.role_name, r.role_description
FROM users u
JOIN roles r ON u.role_id = r.role_id
WHERE u.account_status = 'active' AND u.deleted_at IS NULL;

-- Failed Login Attempts View (Last 24 Hours)
CREATE VIEW vw_failed_logins_24h AS
SELECT 
    ll.*,
    u.full_name,
    u.email,
    u.account_status
FROM login_logs ll
LEFT JOIN users u ON ll.user_id = u.user_id
WHERE ll.status = 'failed' 
    AND ll.login_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY ll.login_time DESC;

-- User Data Summary View
CREATE VIEW vw_user_data_summary AS
SELECT 
    u.user_id,
    u.full_name,
    u.email,
    COUNT(ud.data_id) as total_records,
    SUM(CASE WHEN ud.data_category = 'personal' THEN 1 ELSE 0 END) as personal_count,
    SUM(CASE WHEN ud.data_category = 'financial' THEN 1 ELSE 0 END) as financial_count,
    SUM(CASE WHEN ud.data_category = 'medical' THEN 1 ELSE 0 END) as medical_count,
    MAX(ud.last_modified) as last_activity
FROM users u
LEFT JOIN user_data ud ON u.user_id = ud.user_id
WHERE u.deleted_at IS NULL
GROUP BY u.user_id, u.full_name, u.email;

-- Security Dashboard View
CREATE VIEW vw_security_dashboard AS
SELECT 
    (SELECT COUNT(*) FROM users WHERE account_status = 'locked') as locked_accounts,
    (SELECT COUNT(*) FROM login_logs WHERE status = 'failed' AND login_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)) as failed_24h,
    (SELECT COUNT(*) FROM security_events WHERE severity IN ('high', 'critical') AND is_resolved = FALSE) as open_critical_events,
    (SELECT COUNT(*) FROM login_logs WHERE login_time >= DATE_SUB(NOW(), INTERVAL 1 HOUR)) as logins_1h;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

DELIMITER //

-- Procedure: Lock Account After Failed Attempts
CREATE PROCEDURE sp_lock_account(
    IN p_user_id INT UNSIGNED,
    IN p_lock_duration_minutes INT
)
BEGIN
    UPDATE users 
    SET account_status = 'locked',
        locked_until = DATE_ADD(NOW(), INTERVAL p_lock_duration_minutes MINUTE),
        failed_login_attempts = 0
    WHERE user_id = p_user_id;

    INSERT INTO security_events (event_type, severity, user_id, description)
    VALUES ('account_lock', 'high', p_user_id, 
            CONCAT('Account locked for ', p_lock_duration_minutes, ' minutes due to multiple failed attempts'));
END //

-- Procedure: Record Login Attempt
CREATE PROCEDURE sp_record_login(
    IN p_user_id INT UNSIGNED,
    IN p_username VARCHAR(100),
    IN p_auth_method VARCHAR(50),
    IN p_auth_step VARCHAR(50),
    IN p_ip VARCHAR(45),
    IN p_user_agent TEXT,
    IN p_status VARCHAR(20),
    IN p_failure_reason VARCHAR(255)
)
BEGIN
    INSERT INTO login_logs (user_id, username_attempted, authentication_method, auth_step,
                           ip_address, user_agent, status, failure_reason)
    VALUES (p_user_id, p_username, p_auth_method, p_auth_step, p_ip, p_user_agent, p_status, p_failure_reason);

    IF p_status = 'failed' AND p_user_id IS NOT NULL THEN
        UPDATE users 
        SET failed_login_attempts = failed_login_attempts + 1
        WHERE user_id = p_user_id;

        IF (SELECT failed_login_attempts FROM users WHERE user_id = p_user_id) >= 5 THEN
            CALL sp_lock_account(p_user_id, 30);
        END IF;
    END IF;
END //

-- Procedure: Verify Biometric and Update
CREATE PROCEDURE sp_verify_biometric(
    IN p_user_id INT UNSIGNED,
    IN p_biometric_type VARCHAR(20)
)
BEGIN
    UPDATE biometrics 
    SET last_verified_at = NOW(),
        verification_count = verification_count + 1
    WHERE user_id = p_user_id;

    INSERT INTO login_logs (user_id, authentication_method, auth_step, ip_address, status)
    VALUES (p_user_id, p_biometric_type, 'step_5_complete', CONNECTION_ID(), 'success');
END //

DELIMITER ;

-- ============================================================
-- TRIGGERS
-- ============================================================

DELIMITER //

-- Trigger: Log password changes
CREATE TRIGGER trg_password_change_log
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    IF OLD.password_hash != NEW.password_hash THEN
        INSERT INTO security_events (event_type, severity, user_id, description)
        VALUES ('password_change', 'medium', NEW.user_id, 'Password was changed');
    END IF;
END //

-- Trigger: Log account status changes
CREATE TRIGGER trg_account_status_log
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    IF OLD.account_status != NEW.account_status THEN
        INSERT INTO security_events (event_type, severity, user_id, description)
        VALUES ('account_status_change', 'medium', NEW.user_id, 
                CONCAT('Account status changed from ', OLD.account_status, ' to ', NEW.account_status));
    END IF;
END //

DELIMITER ;

-- ============================================================
-- INITIAL DATA
-- ============================================================

-- Create Super Admin (Change password immediately after deployment)
INSERT INTO users (role_id, full_name, national_id, date_of_birth, gender, email, 
                   phone_number, address, username, password_hash, account_status, email_verified_at)
VALUES (1, 'System Administrator', 'ADMIN001', '1990-01-01', 'other', 'admin@biosecure.local',
        '+1-000-000-0000', 'Secure Facility', 'sysadmin', 
        '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: 'changeme123'
        'active', NOW());

-- ============================================================
-- SECURITY NOTES
-- ============================================================
-- 1. All biometric templates should be encrypted at application level
-- 2. Use prepared statements to prevent SQL injection
-- 3. Enable SSL/TLS for all database connections
-- 4. Implement database-level auditing
-- 5. Regular backup and key rotation
-- 6. Consider using MySQL Enterprise TDE for encryption at rest
-- ============================================================
