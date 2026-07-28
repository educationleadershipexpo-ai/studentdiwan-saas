# Student Diwan — Parent App API Contract

Base URL: configured via `--dart-define=API_URL=<url>` (default: `http://10.0.2.2:3001`)

---

## Authentication

### POST /api/session/login
Login with email and password.

**Request**
```json
{ "email": "parent@school.edu", "password": "secret" }
```

**Response 200**
```json
{
  "token": "<jwt-or-hmac-token>",
  "user": {
    "uid": "u_123",
    "email": "parent@school.edu",
    "displayName": "Sarah Ahmed",
    "role": "parent"
  }
}
```

**Errors**
- `401` — Invalid credentials
- `429` — Rate limited (too many attempts)

**Flutter usage**: `ApiClient.instance.login(email, password)`
**Token storage**: `SharedPreferences` under key `pm_token`
**Token header**: `Authorization: Bearer <token>` (auto-injected by Dio interceptor)

---

### POST /api/session/forgot-password
Trigger a password-reset email.

**Request** `{ "email": "parent@school.edu" }`
**Response 200** `{ "message": "Reset email sent" }`

---

## Generic Data API

All domain data goes through one endpoint family.

### GET /api/data/:entity
Returns an array of records for the entity/table.

| Query Param | Description |
|---|---|
| `studentId` | Filter by student ID |
| `classId`   | Filter by class ID |
| `grade`     | Filter by grade string |
| `uid`       | Filter by user UID |
| `status`    | Filter by status string |
| `audienceRole` | Filter notifications by role |

**Response 200** — array of objects, or `{ data: [...] }`

### GET /api/data/:entity/:id
Single record by ID.

### POST /api/data/:entity
Create a new record. Body is the JSON object.

### PUT /api/data/:entity/:id
Update (merge) a record.

### DELETE /api/data/:entity/:id
Delete a record.

---

## Entity Reference (Mobile App)

| Flutter Constant | API Entity | Backend Table | Notes |
|---|---|---|---|
| `students` | `students` | `students` | Linked by father/mother/guardian email |
| `invoices` | `invoices` | `invoices` | Fees; filter by `studentId` |
| `attendance` | `attendance` | `attendance` | Filter by `studentId` |
| `assignments` | `assignments` | `assignments` | Also covers homework |
| `examMarks` | `exam_marks` | `exam_marks` | Filter by `studentId` |
| `reportCards` | `report_cards` | `report_cards` | Filter by `studentId` |
| `behaviorIncidents` | `behavior_incidents` | `behavior_incidents` | Filter by `studentId` |
| `achievements` | `achievements` | `achievements` | Filter by `studentId` |
| `healthRecords` | `health_records` | `health_records` | Filter by `studentId` |
| `transportEnrollments` | `transport_enrollments` | `transport_enrollments` | Filter by `studentId` |
| `transportRoutes` | `transport_routes` | `transport_routes` | All routes |
| `transportVehicles` | `transport_vehicles` | `transport_vehicles` | All vehicles |
| `libraryLoans` | `library_loans` | `library_loans` | Filter by `studentId` |
| `studyMaterials` | `study_materials` | `study_materials` | Filter by `grade` or `classId` |
| `studentDocuments` | `student_documents` | `student_documents` | Filter by `studentId` |
| `notifications` | `notifications` | `notifications` | Filter by `uid` or `audienceRole` |
| `exams` | `exams` | `exams` | Filter by `grade` |
| `timetableSlots` | `timetable_slots` | `timetable_slots` | Filter by `classId` |
| `notices` | `notices` | `notices` | Filter by `status=Published` |
| `messages` | `messages` | `messages` | Parent inbox |
| `calendarEvents` | `calendar_events` | `calendar_events` | School events |

---

## Push Notifications (FCM)

After login, the app registers the device FCM token via:

```
PUT /api/data/users/:uid  { "fcmToken": "<token>", "fcmPlatform": "android" | "ios" }
```

The backend uses this token to send targeted notifications to the parent's device.

---

## Health Check

```
GET /api/health
Response: { "status": "ok", "db": "mysql" | "sqlite" | "memory" }
```

---

## Error Format

All errors return:
```json
{ "error": "Human-readable message", "code": "OPTIONAL_ERROR_CODE" }
```

HTTP status codes:
- `400` — Bad request / validation error
- `401` — Unauthorized (token missing or expired)
- `403` — Forbidden (wrong role)
- `404` — Entity/record not found
- `429` — Rate limited
- `500` — Server error

---

## Offline Behaviour (Flutter)

The app uses a two-level cache:
1. **In-memory** (`_memCache`) — instant, lives for the session
2. **Hive persistent** (`OfflineCache`) — survives app restarts, TTL = 15 min

On network failure, stale Hive data is returned so every screen stays usable offline. An `ErrorState` with a Retry button is only shown when there is no cached data at all.
