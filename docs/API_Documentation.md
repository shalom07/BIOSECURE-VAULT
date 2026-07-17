# BioSecure Data Vault - API Documentation

## Base URL
```
Production:  https://api.biosecure.local/v1
Staging:     https://staging.biosecure.local/v1
Development: http://localhost:8000/api/v1
```

## Authentication
All API requests (except registration and login step 1) require authentication via:
- **Bearer Token** (JWT) in Authorization header
- **Biometric Verification** for sensitive operations

```
Authorization: Bearer <jwt_token>
X-Biometric-Verified: true
```

---

## Authentication Endpoints

### POST /auth/register
Register a new user with biometric enrollment.

**Request Body:**
```json
{
  "full_name": "John Doe",
  "national_id": "ID123456789",
  "date_of_birth": "1990-01-01",
  "gender": "male",
  "email": "john.doe@email.com",
  "phone_number": "+1234567890",
  "address": "123 Secure St, City",
  "username": "johndoe",
  "password": "SecurePass123!",
  "profile_photo": "base64_encoded_image",
  "fingerprint_template": "base64_encoded_template",
  "iris_template": "base64_encoded_template"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registration successful. Please verify your email.",
  "data": {
    "user_id": 123,
    "email_verification_sent": true
  }
}
```

### POST /auth/login/step1
Validate username and password.

**Request Body:**
```json
{
  "username": "johndoe",
  "password": "SecurePass123!"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Credentials valid. Proceed to biometric authentication.",
  "data": {
    "temp_token": "temp_jwt_token",
    "requires_biometric": true,
    "biometric_methods": ["iris", "fingerprint"]
  }
}
```

### POST /auth/login/step2
Iris scan verification.

**Headers:**
```
Authorization: Bearer <temp_token>
```

**Request Body:**
```json
{
  "iris_scan_data": "base64_encoded_scan",
  "device_info": {
    "type": "webcam",
    "model": "Logitech C920"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Iris verification successful. Proceed to fingerprint.",
  "data": {
    "iris_verified": true,
    "match_score": 98.5
  }
}
```

### POST /auth/login/step3
Fingerprint verification.

**Headers:**
```
Authorization: Bearer <temp_token>
```

**Request Body:**
```json
{
  "fingerprint_scan_data": "base64_encoded_scan",
  "finger_position": "right_index"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Fingerprint verified. 2FA required.",
  "data": {
    "fingerprint_verified": true,
    "requires_2fa": true
  }
}
```

### POST /auth/login/step4
Two-factor authentication.

**Headers:**
```
Authorization: Bearer <temp_token>
```

**Request Body:**
```json
{
  "otp_code": "123456",
  "method": "authenticator_app"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Authentication complete.",
  "data": {
    "access_token": "jwt_access_token",
    "refresh_token": "jwt_refresh_token",
    "expires_in": 3600,
    "user": {
      "id": 123,
      "name": "John Doe",
      "role": "user"
    }
  }
}
```

### POST /auth/logout
Terminate current session.

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully."
}
```

### POST /auth/refresh
Refresh access token.

**Request Body:**
```json
{
  "refresh_token": "jwt_refresh_token"
}
```

### POST /auth/forgot-password
Request password reset.

**Request Body:**
```json
{
  "email": "john.doe@email.com"
}
```

### POST /auth/reset-password
Confirm password reset.

**Request Body:**
```json
{
  "token": "reset_token",
  "new_password": "NewSecurePass123!",
  "new_password_confirmation": "NewSecurePass123!"
}
```

---

## Biometric Endpoints

### POST /biometric/enroll
Enroll new biometric data.

**Request Body:**
```json
{
  "type": "fingerprint",
  "template_data": "base64_encoded_template",
  "metadata": {
    "finger": "right_index",
    "quality_score": 95
  }
}
```

### POST /biometric/verify
Verify biometric data.

**Request Body:**
```json
{
  "type": "iris",
  "scan_data": "base64_encoded_scan"
}
```

### GET /biometric/status
Check enrollment status.

**Response:**
```json
{
  "success": true,
  "data": {
    "iris": {
      "enrolled": true,
      "enrolled_at": "2026-01-15T10:00:00Z",
      "last_verified": "2026-06-11T10:45:22Z"
    },
    "fingerprint": {
      "enrolled": true,
      "enrolled_at": "2026-01-15T10:00:00Z",
      "last_verified": "2026-06-11T10:45:22Z"
    },
    "webauthn": {
      "enrolled": false
    }
  }
}
```

### DELETE /biometric
Remove biometric data.

---

## Data Management Endpoints

### GET /data
List user's data records.

**Query Parameters:**
- `category` (optional): Filter by category
- `search` (optional): Search in title/description
- `page` (optional): Pagination page
- `per_page` (optional): Items per page

**Response:**
```json
{
  "success": true,
  "data": {
    "records": [
      {
        "data_id": 1,
        "title": "Passport Scan",
        "category": "personal",
        "size": 2457600,
        "encrypted": true,
        "created_at": "2026-06-10T14:30:00Z",
        "updated_at": "2026-06-10T14:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_records": 24
    }
  }
}
```

### POST /data
Create new data record.

**Request Body (multipart/form-data):**
- `title`: String (required)
- `description`: String (optional)
- `category`: Enum (required)
- `file`: File (required)
- `tags`: String (optional, comma-separated)

**Response:**
```json
{
  "success": true,
  "message": "Data uploaded and encrypted successfully.",
  "data": {
    "data_id": 25,
    "encryption_status": "encrypted",
    "checksum": "sha256_hash"
  }
}
```

### GET /data/{id}
Retrieve specific record metadata.

### PUT /data/{id}
Update record.

### DELETE /data/{id}
Delete record.

### POST /data/{id}/download
Download decrypted file.

**Response:** File stream with decrypted content.

### POST /data/search
Search records.

**Request Body:**
```json
{
  "query": "passport",
  "filters": {
    "category": ["personal", "legal"],
    "date_from": "2026-01-01",
    "date_to": "2026-12-31"
  }
}
```

### POST /data/export
Export data to format.

**Request Body:**
```json
{
  "format": "pdf",
  "records": [1, 2, 3],
  "include_metadata": true
}
```

---

## Admin Endpoints

### GET /admin/users
List all users (Admin only).

### GET /admin/users/{id}
Get user details.

### POST /admin/users/{id}/lock
Lock user account.

### POST /admin/users/{id}/unlock
Unlock user account.

### GET /admin/logs
View audit logs.

**Query Parameters:**
- `event_type`: Filter by event type
- `severity`: Filter by severity
- `user_id`: Filter by user
- `date_from`, `date_to`: Date range

### GET /admin/security
View security events.

### POST /admin/backup
Trigger system backup.

### GET /admin/dashboard
Get admin dashboard statistics.

**Response:**
```json
{
  "success": true,
  "data": {
    "total_users": 150,
    "active_users": 142,
    "locked_accounts": 3,
    "failed_logins_24h": 12,
    "security_events": {
      "critical": 0,
      "high": 2,
      "medium": 5,
      "low": 18
    },
    "storage_usage": {
      "total": 107374182400,
      "used": 45634027520,
      "free": 61740154880
    }
  }
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request validation failed.",
    "details": {
      "email": ["The email field is required."]
    }
  }
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required."
  }
}
```

### 403 Forbidden
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Insufficient permissions for this operation."
  }
}
```

### 429 Too Many Requests
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "retry_after": 60
  }
}
```

---

## Rate Limits

| Endpoint Group | Limit | Window |
|---------------|-------|--------|
| Authentication | 5 requests | 1 minute |
| Biometric | 10 requests | 1 minute |
| Data Operations | 100 requests | 1 minute |
| Admin Operations | 50 requests | 1 minute |

---

## Webhook Events

System supports webhooks for:
- `user.registered`
- `user.locked`
- `biometric.enrolled`
- `data.uploaded`
- `security.alert`
- `backup.completed`

**Webhook Payload:**
```json
{
  "event": "security.alert",
  "timestamp": "2026-06-11T10:45:22Z",
  "data": {
    "alert_type": "failed_login",
    "user_id": 123,
    "severity": "high",
    "details": {}
  }
}
```

---

**Document Version:** 1.0.0
**Last Updated:** 2026-07-13
