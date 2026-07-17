## BioSecure Data Vault - Entity Relationship Diagram

```mermaid
erDiagram
    ROLES ||--o{ USERS : assigns
    USERS ||--o| BIOMETRICS : enrolls
    USERS ||--o{ LOGIN_LOGS : generates
    USERS ||--o{ USER_DATA : owns
    USERS ||--o{ DATA_ACCESS_LOGS : accesses
    USERS ||--o{ SECURITY_EVENTS : triggers
    USERS ||--o{ BACKUP_RECORDS : creates
    USERS ||--o{ PASSWORD_RESETS : requests
    USERS ||--o{ EMAIL_VERIFICATIONS : verifies
    USER_DATA ||--o{ DATA_ACCESS_LOGS : tracked_by

    ROLES {
        int role_id PK
        string role_name UK
        string role_description
        json permissions
        timestamp created_at
        timestamp updated_at
    }

    USERS {
        int user_id PK
        int role_id FK
        string full_name
        string national_id UK
        date date_of_birth
        enum gender
        string email UK
        string phone_number
        text address
        string username UK
        string password_hash
        string profile_photo
        timestamp email_verified_at
        boolean two_factor_enabled
        string two_factor_secret
        text two_factor_recovery_codes
        enum account_status
        int failed_login_attempts
        timestamp locked_until
        timestamp last_login_at
        string last_login_ip
        string session_token
        timestamp session_expires_at
        string encryption_key_id
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }

    BIOMETRICS {
        int biometric_id PK
        int user_id FK,UK
        blob fingerprint_template
        string fingerprint_template_hash
        blob iris_template
        string iris_template_hash
        text biometric_public_key
        string credential_id
        json webauthn_data
        timestamp enrollment_date
        timestamp last_verified_at
        int verification_count
        int template_version
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    LOGIN_LOGS {
        bigint log_id PK
        int user_id FK
        string username_attempted
        timestamp login_time
        timestamp logout_time
        enum authentication_method
        enum auth_step
        string ip_address
        text user_agent
        string device_fingerprint
        json geolocation
        enum status
        string failure_reason
        string session_id
        decimal risk_score
        boolean is_suspicious
    }

    USER_DATA {
        int data_id PK
        int user_id FK
        string data_title
        text data_description
        enum data_category
        longtext data_content
        boolean data_content_encrypted
        string encryption_iv
        string file_path
        bigint file_size
        string file_mime_type
        string checksum
        boolean is_favorite
        int access_count
        timestamp upload_date
        timestamp last_modified
        timestamp last_accessed
        int created_by FK
        int modified_by FK
    }

    DATA_ACCESS_LOGS {
        bigint access_id PK
        int data_id FK
        int user_id FK
        enum access_type
        timestamp access_time
        string ip_address
        text user_agent
    }

    SECURITY_EVENTS {
        bigint event_id PK
        enum event_type
        enum severity
        int user_id FK
        text description
        string ip_address
        text user_agent
        json metadata
        boolean is_resolved
        int resolved_by FK
        timestamp resolved_at
        timestamp created_at
    }

    BACKUP_RECORDS {
        int backup_id PK
        string backup_name
        enum backup_type
        string backup_path
        bigint backup_size
        string checksum
        boolean encryption_status
        int created_by FK
        timestamp created_at
        timestamp completed_at
        enum status
    }

    PASSWORD_RESETS {
        int reset_id PK
        int user_id FK
        string token_hash
        timestamp expires_at
        timestamp used_at
        string ip_address
        timestamp created_at
    }

    EMAIL_VERIFICATIONS {
        int verification_id PK
        int user_id FK
        string email
        string token_hash
        timestamp expires_at
        timestamp verified_at
        timestamp created_at
    }
```

### Relationship Cardinality

| Relationship | Type | Description |
|-------------|------|-------------|
| ROLES → USERS | 1:N | One role can be assigned to many users |
| USERS → BIOMETRICS | 1:1 | One user has exactly one biometric record |
| USERS → LOGIN_LOGS | 1:N | One user generates many login logs |
| USERS → USER_DATA | 1:N | One user owns many data records |
| USERS → DATA_ACCESS_LOGS | 1:N | One user creates many access logs |
| USER_DATA → DATA_ACCESS_LOGS | 1:N | One data record has many access logs |
| USERS → SECURITY_EVENTS | 1:N | One user triggers many security events |
| USERS → BACKUP_RECORDS | 1:N | One user can create many backups |
| USERS → PASSWORD_RESETS | 1:N | One user can request many password resets |
| USERS → EMAIL_VERIFICATIONS | 1:N | One user can have many verification attempts |

### Index Strategy
- **Primary Keys**: All tables use AUTO_INCREMENT INT/BIGINT
- **Unique Constraints**: national_id, email, username, user_id in biometrics
- **Foreign Keys**: Properly indexed for JOIN performance
- **Search Indexes**: Full-text on data_title + data_description
- **Audit Indexes**: login_time, ip_address for security queries
- **Status Indexes**: account_status, event severity for dashboard queries
