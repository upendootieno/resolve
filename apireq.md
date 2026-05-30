# Eye Resolve — API & Data Requirements Documentation

> **Purpose of this document**  
> Every screen in Eye Resolve currently renders either hard-coded data or calls open, unauthenticated third-party services. This document maps every data point shown in the app to the REST API endpoint that must serve it, defines the exact data types for each field, explains *why* each field is necessary, and describes what a production back-end for this app must implement.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Authentication API](#2-authentication-api)
3. [Patient Profile API](#3-patient-profile-api)
4. [Eye Pressure / Tracker API](#4-eye-pressure--tracker-api)
5. [Appointments API](#5-appointments-api)
6. [Clinics & Location API](#6-clinics--location-api)
7. [Medications API](#7-medications-api)
8. [Dose Logging & Compliance API](#8-dose-logging--compliance-api)
9. [Messaging / Inbox API](#9-messaging--inbox-api)
10. [Notifications / Alerts API](#10-notifications--alerts-api)
11. [Third-Party APIs Already in Use](#11-third-party-apis-already-in-use)
12. [Database Schema Summary](#12-database-schema-summary)
13. [Global Data Type Reference](#13-global-data-type-reference)

---

## 1. Architecture Overview

```
Flutter App (Eye Resolve)
        │
        ├── Auth token (JWT / OAuth2)
        │
        ├── Eye Resolve REST API  ─────────── PostgreSQL (schema.sql)
        │     └── /api/v1/...
        │
        ├── Nominatim (OpenStreetMap) ──────── geocoding (already live)
        ├── Overpass API ───────────────────── nearby clinic search (already live)
        └── Google Maps (url_launcher) ──────── directions (already live)
```

All custom back-end calls go through a single base URL, e.g. `https://api.eyeresolve.app/api/v1`. Every authenticated request carries an `Authorization: Bearer <token>` header.

---

## 2. Authentication API

### Why it is needed
The app greets users by name ("Good morning, Patient"), stores their readings, medications, appointments, and messages per individual. None of that is possible without knowing *who* the user is. Every other API in this document depends on a resolved patient identity.

### Endpoints

#### `POST /auth/register`
Registers a new patient account.

**Request body**

| Field | Type | Required | Description |
|---|---|---|---|
| `email` | `String` | ✅ | Unique email address used as login identifier |
| `password` | `String` | ✅ | Min 8 chars, hashed server-side (bcrypt / argon2) |
| `full_name` | `String` | ✅ | Displayed as "Good morning, {first_name}" on the Home screen |
| `date_of_birth` | `String (ISO 8601 date)` | ✅ | Used for age-based clinical thresholds |
| `phone_number` | `String \| null` | ❌ | Used for SMS refill/appointment reminders |
| `avatar_url` | `String (URL) \| null` | ❌ | Profile photo shown in top bar and messages |

**Response**

```json
{
  "patient_id": "uuid-v4",
  "email": "patient@example.com",
  "full_name": "Jane Doe",
  "access_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

| Field | Type | Why needed |
|---|---|---|
| `patient_id` | `String (UUID)` | Foreign key used in every other API resource |
| `access_token` | `String (JWT)` | Attached as `Authorization` header on every subsequent request |
| `expires_in` | `int (seconds)` | App uses this to schedule token refresh before expiry |

---

#### `POST /auth/login`

**Request body**

| Field | Type | Required |
|---|---|---|
| `email` | `String` | ✅ |
| `password` | `String` | ✅ |

**Response** — same shape as `/auth/register` response above.

---

#### `POST /auth/refresh`

**Request body**

| Field | Type | Required |
|---|---|---|
| `refresh_token` | `String` | ✅ |

**Response**

| Field | Type |
|---|---|
| `access_token` | `String (JWT)` |
| `expires_in` | `int` |

---

#### `POST /auth/logout`
Invalidates the refresh token server-side. No body required beyond the `Authorization` header.

---

## 3. Patient Profile API

### Why it is needed
The Home screen personalises the greeting with the patient's name, shows their doctor's name and photo in the "Next Appointment" card, and displays a contextual health summary. All of this data must be pulled from a server profile rather than being hard-coded.

### Endpoint

#### `GET /patients/me`

**Response**

```json
{
  "patient_id": "uuid-v4",
  "full_name": "Jane Doe",
  "first_name": "Jane",
  "email": "patient@example.com",
  "phone_number": "+1-555-0100",
  "avatar_url": "https://cdn.eyeresolve.app/avatars/uuid.jpg",
  "date_of_birth": "1985-04-12",
  "diagnosis": "Glaucoma",
  "diagnosis_date": "2022-01-15",
  "primary_doctor": {
    "doctor_id": "uuid-v4",
    "full_name": "Dr. Smith",
    "specialty": "Ophthalmologist",
    "clinic_name": "Main Clinic",
    "avatar_url": "https://cdn.eyeresolve.app/doctors/uuid.jpg"
  }
}
```

| Field | Type | Why needed |
|---|---|---|
| `first_name` | `String` | Personalises greeting: "Good morning, Jane" |
| `diagnosis` | `String` | Drives contextual health tip on Home screen |
| `primary_doctor.full_name` | `String` | Displayed in the Next Appointment card |
| `primary_doctor.specialty` | `String` | Subtitle under doctor name in appointment card |
| `primary_doctor.clinic_name` | `String` | Subtitle under doctor name in appointment card |
| `primary_doctor.avatar_url` | `String (URL)` | Doctor's photo in the appointment card circle avatar |

---

#### `PATCH /patients/me`
Updates editable profile fields. Used by the Settings panel.

**Request body** — all fields optional (partial update):

| Field | Type |
|---|---|
| `full_name` | `String` |
| `phone_number` | `String \| null` |
| `avatar_url` | `String (URL) \| null` |

---

## 4. Eye Pressure / Tracker API

### Why it is needed
The Tracker tab is the clinical core of the app. It currently shows hard-coded readings (`14.5 mmHg`, `16.5 mmHg`, etc.) and a hard-coded 7-day trend chart. In production these must be real per-patient measurements stored in the database, with the Home screen card showing the most recent reading and the chart calculating the 7-day average.

The app also already implements a "Quick Log Pressure" dialog that collects a numeric value from the user and must persist it to the server.

### Data model — `PressureReading`

| Field | Type | Description |
|---|---|---|
| `reading_id` | `String (UUID)` | Primary key |
| `patient_id` | `String (UUID)` | FK → patients |
| `value_mmhg` | `double` | The measured IOP in millimetres of mercury |
| `eye` | `String enum: "left" \| "right" \| "both"` | Which eye was measured |
| `recorded_at` | `String (ISO 8601 datetime, UTC)` | When the reading was taken |
| `device` | `String \| null` | Tonometer model used (e.g. "iCare Home 2") |
| `notes` | `String \| null` | Free text — patient or doctor notes |
| `is_flagged` | `bool` | `true` when `value_mmhg > 21` (high IOP threshold) |
| `created_at` | `String (ISO 8601 datetime)` | Server insertion timestamp |

---

### Endpoints

#### `GET /patients/me/pressure-readings`

**Query parameters**

| Param | Type | Default | Description |
|---|---|---|---|
| `limit` | `int` | `20` | Max results per page |
| `offset` | `int` | `0` | Pagination offset |
| `from_date` | `String (ISO 8601 date)` | — | Filter start date |
| `to_date` | `String (ISO 8601 date)` | — | Filter end date |

**Response**

```json
{
  "total": 42,
  "readings": [
    {
      "reading_id": "uuid",
      "value_mmhg": 14.0,
      "eye": "both",
      "recorded_at": "2026-05-29T09:15:00Z",
      "device": null,
      "notes": null,
      "is_flagged": false
    }
  ]
}
```

---

#### `POST /patients/me/pressure-readings`
Called when the user saves a reading in the "Quick Log Pressure" or "Add New Reading" dialogs.

**Request body**

| Field | Type | Required |
|---|---|---|
| `value_mmhg` | `double` | ✅ |
| `eye` | `String enum` | ✅ |
| `recorded_at` | `String (ISO 8601)` | ✅ |
| `device` | `String \| null` | ❌ |
| `notes` | `String \| null` | ❌ |

**Response** — the newly created `PressureReading` object.

---

#### `GET /patients/me/pressure-readings/summary`
Powers the Home screen card ("TODAY'S EYE PRESSURE – 14 mmHg, Normal Range") and the Tracker trend card ("7-Day Trend, 14.2 mmHg Avg, –2.1%").

**Response**

```json
{
  "latest": {
    "value_mmhg": 14.0,
    "recorded_at": "2026-05-30T08:30:00Z",
    "status": "normal"
  },
  "seven_day_avg_mmhg": 14.2,
  "seven_day_change_percent": -2.1,
  "daily_values": [
    { "date": "2026-05-24", "avg_mmhg": 14.5 },
    { "date": "2026-05-25", "avg_mmhg": 14.0 },
    { "date": "2026-05-26", "avg_mmhg": 13.8 },
    { "date": "2026-05-27", "avg_mmhg": 14.2 },
    { "date": "2026-05-28", "avg_mmhg": 14.6 },
    { "date": "2026-05-29", "avg_mmhg": 14.3 },
    { "date": "2026-05-30", "avg_mmhg": 14.0 }
  ]
}
```

| Field | Type | Why needed |
|---|---|---|
| `latest.value_mmhg` | `double` | Large "14 mmHg" number on the Home dashboard card |
| `latest.status` | `String enum: "normal" \| "elevated" \| "high"` | Drives the "Normal Range" / warning badge colour |
| `latest.recorded_at` | `String (ISO 8601)` | "Last recorded: 2 hours ago" timestamp |
| `seven_day_avg_mmhg` | `double` | "14.2 mmHg Avg" in the Tracker trend card |
| `seven_day_change_percent` | `double` | "–2.1%" badge in the Tracker trend card |
| `daily_values` | `List<{date: String, avg_mmhg: double}>` | X/Y data points for the 7-bar/line chart in the Tracker |

---

## 5. Appointments API

### Why it is needed
The Home screen shows a prominently styled "Next Appointment" card containing the date/time, doctor name and photo. This data is completely hard-coded today ("Tomorrow, 10:00 AM", "Dr. Smith"). In production it must be fetched from a real scheduling system so patients always see their actual upcoming visit.

### Data model — `Appointment`

| Field | Type | Description |
|---|---|---|
| `appointment_id` | `String (UUID)` | Primary key |
| `patient_id` | `String (UUID)` | FK → patients |
| `doctor_id` | `String (UUID)` | FK → doctors |
| `clinic_id` | `String (UUID)` | FK → clinics |
| `scheduled_at` | `String (ISO 8601 datetime, UTC)` | Date and time of the visit |
| `duration_minutes` | `int` | Length of appointment slot |
| `type` | `String enum: "checkup" \| "follow_up" \| "procedure" \| "emergency"` | Visit category |
| `status` | `String enum: "confirmed" \| "pending" \| "cancelled" \| "completed"` | Booking status |
| `notes` | `String \| null` | Pre-visit instructions or context |

---

### Endpoints

#### `GET /patients/me/appointments/next`
Used by the Home screen to populate the "Next Appointment" card.

**Response**

```json
{
  "appointment_id": "uuid",
  "scheduled_at": "2026-05-31T10:00:00Z",
  "duration_minutes": 30,
  "type": "follow_up",
  "status": "confirmed",
  "doctor": {
    "doctor_id": "uuid",
    "full_name": "Dr. Smith",
    "specialty": "Ophthalmologist",
    "clinic_name": "Main Clinic",
    "avatar_url": "https://cdn.eyeresolve.app/doctors/uuid.jpg",
    "clinic_latitude": -1.2921,
    "clinic_longitude": 36.8219
  }
}
```

| Field | Type | Why needed |
|---|---|---|
| `scheduled_at` | `String (ISO 8601)` | Displayed as "Tomorrow, 10:00 AM" — formatted client-side |
| `doctor.full_name` | `String` | "Dr. Smith" label in appointment card |
| `doctor.specialty` | `String` | "Ophthalmologist • Main Clinic" subtitle |
| `doctor.avatar_url` | `String (URL)` | Doctor's `CircleAvatar` photo |
| `doctor.clinic_latitude` | `double` | Used to build the Google Maps "Get Directions" URL |
| `doctor.clinic_longitude` | `double` | Used to build the Google Maps "Get Directions" URL |

---

#### `GET /patients/me/appointments`
Full appointment history with pagination for a future "All Appointments" view.

**Query parameters**: `limit`, `offset`, `status`, `from_date`, `to_date`

---

#### `POST /patients/me/appointments`
Book a new appointment (future booking flow).

---

#### `PATCH /patients/me/appointments/{appointment_id}`
Cancel or reschedule an appointment.

---

## 6. Clinics & Location API

### Why it is needed
The Clinics tab already performs real-time searches using two open third-party APIs (Nominatim for geocoding and Overpass for POI lookup). However, those APIs have no knowledge of Eye Resolve-specific data: consultation prices, wait times, accepted insurance, specialties, or whether a clinic is affiliated with the patient's care network. A custom Clinics API adds that enrichment layer on top of the open geographic data.

### Third-party calls already implemented (no back-end needed for these)

| Service | Call | Data returned |
|---|---|---|
| **Nominatim** `GET https://nominatim.openstreetmap.org/search` | Geocode a typed place name | `lat: double`, `lon: double` |
| **Overpass API** `POST https://overpass-api.de/api/interpreter` | Find medical amenity nodes/ways within 12 km | `name`, `amenity`, `addr:*`, `lat/lon`, `opening_hours` |

### Custom Clinic enrichment endpoint

#### `POST /clinics/enrich`
Takes a list of OSM place IDs or `(lat, lon)` pairs and returns Eye Resolve-specific metadata for any that are in the database.

**Request body**

```json
{
  "locations": [
    { "osm_id": "node/123456", "latitude": -1.29, "longitude": 36.82 },
    { "osm_id": "way/654321",  "latitude": -1.31, "longitude": 36.84 }
  ]
}
```

**Response**

```json
{
  "enriched": [
    {
      "osm_id": "node/123456",
      "clinic_id": "uuid",
      "name": "Central Eye Clinic",
      "phone": "+254 20 123 4567",
      "email": "info@centraleyeclinic.ke",
      "website": "https://centraleyeclinic.ke",
      "standard_checkup_price_usd": 45.00,
      "currency": "USD",
      "accepted_specialties": ["Glaucoma", "Cataracts", "Retina"],
      "average_wait_minutes": 20,
      "rating": 4.6,
      "review_count": 112,
      "is_network_partner": true,
      "opening_hours_structured": {
        "monday":    { "open": "08:00", "close": "18:00" },
        "tuesday":   { "open": "08:00", "close": "18:00" },
        "wednesday": { "open": "08:00", "close": "18:00" },
        "thursday":  { "open": "08:00", "close": "18:00" },
        "friday":    { "open": "08:00", "close": "17:00" },
        "saturday":  { "open": "09:00", "close": "13:00" },
        "sunday":    null
      }
    }
  ]
}
```

| Field | Type | Why needed |
|---|---|---|
| `standard_checkup_price_usd` | `double` | "$45.00" price tag shown in the old clinic card design (restored when real data is available) |
| `accepted_specialties` | `List<String>` | Drives the Cataracts / Glaucoma / Optometry / Retina filter chips |
| `average_wait_minutes` | `int` | "Premium facility with shortest wait times" badge |
| `rating` | `double` | Star rating in clinic card |
| `is_network_partner` | `bool` | "Cheapest in your area for this service" / network badge |
| `opening_hours_structured` | `Map<String, {open, close} \| null>` | Real "Open now" / "Closes at 6 PM" status instead of "Hours not listed" |
| `phone` / `website` | `String` | "Call Clinic" and "Visit Website" buttons (future feature) |

---

## 7. Medications API

### Why it is needed
The Medications tab shows two hard-coded drugs (Latanoprost and Timolol) with fixed schedules and doses. Every patient has a different prescription. The app must load the current patient's active medications from the server so the correct names, doses, schedules, and refill deadlines are displayed.

### Data model — `Medication`

| Field | Type | Description |
|---|---|---|
| `medication_id` | `String (UUID)` | Primary key |
| `patient_id` | `String (UUID)` | FK → patients |
| `name` | `String` | Drug name, e.g. "Latanoprost" |
| `generic_name` | `String \| null` | INN name, e.g. "latanoprost" |
| `schedule` | `String enum: "once_daily" \| "twice_daily" \| "nightly" \| "as_needed"` | Dosing frequency |
| `schedule_label` | `String` | Human label shown on card: "Nightly", "Twice Daily" |
| `dose_instruction` | `String` | E.g. "1 drop nightly in each eye" |
| `eye` | `String enum: "left" \| "right" \| "both" \| null` | Which eye(s) |
| `prescribed_by` | `String (UUID — doctor_id)` | FK → doctors |
| `started_on` | `String (ISO 8601 date)` | Prescription start date |
| `refill_due_on` | `String (ISO 8601 date)` | Next refill deadline |
| `days_remaining` | `int` | Server-calculated days of supply left |
| `is_active` | `bool` | Whether the prescription is current |

---

### Endpoints

#### `GET /patients/me/medications`

**Query parameters**: `is_active=true` (default) filters to current prescriptions.

**Response**

```json
{
  "medications": [
    {
      "medication_id": "uuid",
      "name": "Latanoprost",
      "generic_name": "latanoprost",
      "schedule": "nightly",
      "schedule_label": "Nightly",
      "dose_instruction": "1 drop nightly",
      "eye": "both",
      "refill_due_on": "2026-06-03",
      "days_remaining": 4,
      "is_active": true
    }
  ]
}
```

| Field | Type | Why needed |
|---|---|---|
| `name` | `String` | Med card title and snackbar text ("✓ Dose logged for Latanoprost") |
| `schedule_label` | `String` | Badge pill on the medication card |
| `dose_instruction` | `String` | Subtitle on the medication card |
| `days_remaining` | `int` | "Approx. 4 days remaining" refill alert bar |
| `refill_due_on` | `String (ISO date)` | Used to decide whether to show the refill warning banner |

---

#### `GET /patients/me/medications/{medication_id}`
Single medication detail for a future "Medication Detail" screen.

---

## 8. Dose Logging & Compliance API

### Why it is needed
The "Log Dose" button on each medication card currently only shows a snackbar — nothing is persisted. The Weekly Compliance card ("94%", "13/14 Doses Done") is also hard-coded. In production, every dose log must be stored, and the compliance percentage must be calculated server-side from actual logs vs. expected doses.

### Data model — `DoseLog`

| Field | Type | Description |
|---|---|---|
| `log_id` | `String (UUID)` | Primary key |
| `patient_id` | `String (UUID)` | FK → patients |
| `medication_id` | `String (UUID)` | FK → medications |
| `logged_at` | `String (ISO 8601 datetime, UTC)` | When the patient took or logged the dose |
| `status` | `String enum: "taken" \| "missed" \| "skipped"` | Dose outcome |
| `notes` | `String \| null` | Optional patient note |

---

### Endpoints

#### `POST /patients/me/dose-logs`
Called by "Log Dose" button on each medication card.

**Request body**

| Field | Type | Required |
|---|---|---|
| `medication_id` | `String (UUID)` | ✅ |
| `logged_at` | `String (ISO 8601)` | ✅ |
| `status` | `String enum` | ✅ (default `"taken"`) |
| `notes` | `String \| null` | ❌ |

**Response** — the new `DoseLog` object.

---

#### `GET /patients/me/compliance/weekly`
Powers the "Weekly Compliance" card in the Medications tab.

**Response**

```json
{
  "period_start": "2026-05-25",
  "period_end": "2026-05-31",
  "doses_expected": 14,
  "doses_taken": 13,
  "compliance_percent": 92.86,
  "streak_days": 6,
  "per_medication": [
    {
      "medication_id": "uuid",
      "name": "Latanoprost",
      "doses_expected": 7,
      "doses_taken": 7,
      "compliance_percent": 100.0
    },
    {
      "medication_id": "uuid",
      "name": "Timolol",
      "doses_expected": 14,
      "doses_taken": 13,
      "compliance_percent": 92.86
    }
  ]
}
```

| Field | Type | Why needed |
|---|---|---|
| `compliance_percent` | `double` | `LinearProgressIndicator` value (divided by 100) |
| `doses_expected` / `doses_taken` | `int` | "13/14 Doses Done" label |
| `streak_days` | `int` | Future gamification / streak badge |

---

#### `POST /patients/me/refill-alerts`
Called when "Refill Alert" is tapped. Creates a server-side reminder.

**Request body**

| Field | Type | Required |
|---|---|---|
| `medication_id` | `String (UUID)` | ✅ |
| `remind_on` | `String (ISO 8601 date)` | ✅ |
| `channel` | `String enum: "push" \| "sms" \| "email"` | ✅ |

---

## 9. Messaging / Inbox API

### Why it is needed
The Inbox tab currently shows three hard-coded messages. In production, patients exchange real messages with their care team and participate in community groups. All message content, timestamps, sender profiles, and read/unread state must come from the API.

### Data model — `Message`

| Field | Type | Description |
|---|---|---|
| `message_id` | `String (UUID)` | Primary key |
| `thread_id` | `String (UUID)` | Groups replies into a conversation |
| `sender_id` | `String (UUID)` | FK → users (patient or doctor) |
| `recipient_id` | `String (UUID) \| null` | FK → users; `null` for group messages |
| `group_id` | `String (UUID) \| null` | FK → groups; `null` for 1-to-1 messages |
| `category` | `String enum: "medical" \| "community" \| "alert"` | Drives Inbox tab filtering (All / Community / Alerts) |
| `subject` | `String` | Bold title line in message list item |
| `body` | `String` | Full message text shown in the bottom sheet detail view |
| `sent_at` | `String (ISO 8601 datetime)` | "10:24 AM", "Yesterday", "Mon" timestamp |
| `is_read` | `bool` | Controls unread badge (future feature) |
| `sender_name` | `String` | Displayed in message list — resolved server-side |
| `sender_avatar_url` | `String (URL) \| null` | CircleAvatar image for sender |

---

### Endpoints

#### `GET /patients/me/messages`

**Query parameters**

| Param | Type | Description |
|---|---|---|
| `category` | `String enum \| "all"` | Maps to "All Messages", "Community", "Alerts" tabs |
| `limit` | `int` | Default `30` |
| `offset` | `int` | Pagination |
| `is_read` | `bool \| null` | Filter unread only |

**Response**

```json
{
  "total": 12,
  "messages": [
    {
      "message_id": "uuid",
      "thread_id": "uuid",
      "category": "medical",
      "subject": "Dr. Smith (Follow-up)",
      "body": "The results from your visual field test look promising...",
      "sent_at": "2026-05-30T10:24:00Z",
      "is_read": true,
      "sender_name": "Dr. Smith",
      "sender_avatar_url": "https://cdn.eyeresolve.app/doctors/uuid.jpg"
    }
  ]
}
```

| Field | Type | Why needed |
|---|---|---|
| `category` | `String` | Controls which Inbox tab (`All` / `Community` / `Alerts`) the message appears in |
| `subject` | `String` | Bold title in `_MessageItem` widget |
| `body` | `String` | Full text shown in the bottom sheet when message is tapped |
| `sent_at` | `String (ISO 8601)` | Relative time label "10:24 AM" / "Yesterday" / "Mon" |
| `sender_avatar_url` | `String (URL) \| null` | `CircleAvatar` image — `null` falls back to icon |

---

#### `POST /patients/me/messages`
Called by the "New Message" compose sheet "Send" button.

**Request body**

| Field | Type | Required |
|---|---|---|
| `recipient_id` | `String (UUID)` | ✅ (doctor's ID, or group ID) |
| `category` | `String enum` | ✅ |
| `subject` | `String` | ✅ |
| `body` | `String` | ✅ |

---

#### `PATCH /patients/me/messages/{message_id}/read`
Marks a message as read when opened. No body needed.

---

#### `GET /groups`
Lists available community support groups shown in the "Featured Group" card.

**Response**

```json
{
  "groups": [
    {
      "group_id": "uuid",
      "name": "Support Group (Weekly Q&A)",
      "description": "Live discussion starts in 2 hours. Join 45 others.",
      "member_count": 45,
      "next_session_at": "2026-05-30T14:00:00Z",
      "is_featured": true
    }
  ]
}
```

---

## 10. Notifications / Alerts API

### Why it is needed
The "Refill Alert" button and the appointment reminder both result in notifications being sent to the patient. Push notifications require a device token registered on the server. The Alerts Inbox tab also shows server-generated alerts such as high IOP readings, missed doses, and upcoming appointments.

### Endpoints

#### `POST /patients/me/device-tokens`
Registers the device for push notifications (FCM on Android, APNs on iOS).

**Request body**

| Field | Type | Required |
|---|---|---|
| `token` | `String` | ✅ |
| `platform` | `String enum: "android" \| "ios"` | ✅ |

---

#### `GET /patients/me/alerts`
Returns system-generated alerts (high IOP, missed dose, appointment in 24 h).

**Response**

```json
{
  "alerts": [
    {
      "alert_id": "uuid",
      "type": "high_iop",
      "title": "High Eye Pressure Detected",
      "body": "Your reading of 21.5 mmHg on May 26 is above the normal range.",
      "severity": "warning",
      "created_at": "2026-05-26T07:50:00Z",
      "is_read": false
    }
  ]
}
```

| Field | Type | Why needed |
|---|---|---|
| `type` | `String enum: "high_iop" \| "missed_dose" \| "appointment_reminder" \| "refill_due"` | Determines icon and colour in the Alerts tab |
| `severity` | `String enum: "info" \| "warning" \| "critical"` | Drives the highlighted (red-bordered) `_ReadingCard` in Tracker |
| `is_read` | `bool` | Unread badge count on the Inbox nav tab |

---

## 11. Third-Party APIs Already in Use

These are fully implemented in the app and require **no custom back-end code**. They are documented here for completeness.

### 11.1 Nominatim (OpenStreetMap Geocoding)

| Property | Value |
|---|---|
| **Endpoint** | `GET https://nominatim.openstreetmap.org/search` |
| **Auth** | None (rate-limited to 1 req/s per IP; use a custom `User-Agent` header) |
| **Cost** | Free, open data |
| **Called when** | User types a place name in the Clinics search box and taps the search button |

**Query params used**

| Param | Type | Value |
|---|---|---|
| `q` | `String` | User's typed search string |
| `format` | `String` | `"jsonv2"` |
| `limit` | `int` | `1` |

**Fields consumed from response**

| Field | Type | Used for |
|---|---|---|
| `lat` | `String → double` | Centre latitude for Overpass search |
| `lon` | `String → double` | Centre longitude for Overpass search |

---

### 11.2 Overpass API (OpenStreetMap POI Search)

| Property | Value |
|---|---|
| **Endpoint** | `POST https://overpass-api.de/api/interpreter` |
| **Auth** | None (public) |
| **Cost** | Free, open data |
| **Called when** | GPS coordinates resolve (auto on page load) or after Nominatim geocodes a search |

**Query**: Finds all nodes/ways/relations tagged with `amenity` ∈ `{clinic, doctors, hospital, optometrist, ophthalmologist}` within 12 km of the given coordinates.

**Fields consumed from each element**

| OSM tag | Dart field | Type | Used for |
|---|---|---|---|
| `name` | `_ClinicPlace.name` | `String` | Clinic card title |
| `amenity` | `_ClinicPlace.category` | `String` | Category badge pill |
| `addr:housenumber` + `addr:street` + `addr:suburb` + `addr:city` | `_ClinicPlace.address` | `String` | Address subtitle in clinic card |
| `lat` / `lon` (or `center.lat` / `center.lon`) | `_ClinicPlace.latitude`, `.longitude` | `double` | Distance calculation + Directions URL |
| `opening_hours` | `_ClinicPlace.isOpen` | `bool?` | "Open now" / "Currently closed" status |

---

### 11.3 Google Maps (url_launcher)

| Property | Value |
|---|---|
| **Integration** | Deep link via `url_launcher` — no API key required for basic map search |
| **URL template** | `https://www.google.com/maps/search/?api=1&query={lat},{lon}` |
| **Called when** | User taps "Directions" on a clinic card, or "Get Directions" on the appointment card |

---

## 12. Database Schema Summary

The `backend/schema.sql` file should define the following tables, aligned with the API data models above.

```sql
-- Users & Auth
CREATE TABLE patients (
  patient_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email             TEXT UNIQUE NOT NULL,
  password_hash     TEXT NOT NULL,
  full_name         TEXT NOT NULL,
  phone_number      TEXT,
  avatar_url        TEXT,
  date_of_birth     DATE,
  diagnosis         TEXT,
  diagnosis_date    DATE,
  primary_doctor_id UUID REFERENCES doctors(doctor_id),
  created_at        TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE doctors (
  doctor_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name    TEXT NOT NULL,
  specialty    TEXT,
  clinic_name  TEXT,
  avatar_url   TEXT,
  clinic_lat   DOUBLE PRECISION,
  clinic_lon   DOUBLE PRECISION
);

-- Pressure Readings
CREATE TABLE pressure_readings (
  reading_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id   UUID REFERENCES patients(patient_id) ON DELETE CASCADE,
  value_mmhg   DOUBLE PRECISION NOT NULL,
  eye          TEXT CHECK (eye IN ('left','right','both')) DEFAULT 'both',
  recorded_at  TIMESTAMPTZ NOT NULL,
  device       TEXT,
  notes        TEXT,
  is_flagged   BOOLEAN GENERATED ALWAYS AS (value_mmhg > 21) STORED,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- Appointments
CREATE TABLE appointments (
  appointment_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id       UUID REFERENCES patients(patient_id) ON DELETE CASCADE,
  doctor_id        UUID REFERENCES doctors(doctor_id),
  scheduled_at     TIMESTAMPTZ NOT NULL,
  duration_minutes INT DEFAULT 30,
  type             TEXT CHECK (type IN ('checkup','follow_up','procedure','emergency')),
  status           TEXT CHECK (status IN ('confirmed','pending','cancelled','completed')) DEFAULT 'pending',
  notes            TEXT
);

-- Medications
CREATE TABLE medications (
  medication_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id       UUID REFERENCES patients(patient_id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  generic_name     TEXT,
  schedule         TEXT CHECK (schedule IN ('once_daily','twice_daily','nightly','as_needed')),
  schedule_label   TEXT,
  dose_instruction TEXT,
  eye              TEXT,
  prescribed_by    UUID REFERENCES doctors(doctor_id),
  started_on       DATE,
  refill_due_on    DATE,
  is_active        BOOLEAN DEFAULT true
);

-- Dose Logs
CREATE TABLE dose_logs (
  log_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id    UUID REFERENCES patients(patient_id) ON DELETE CASCADE,
  medication_id UUID REFERENCES medications(medication_id),
  logged_at     TIMESTAMPTZ NOT NULL,
  status        TEXT CHECK (status IN ('taken','missed','skipped')) DEFAULT 'taken',
  notes         TEXT
);

-- Messages
CREATE TABLE messages (
  message_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id        UUID NOT NULL,
  sender_id        UUID NOT NULL,
  recipient_id     UUID,
  group_id         UUID,
  category         TEXT CHECK (category IN ('medical','community','alert')) NOT NULL,
  subject          TEXT NOT NULL,
  body             TEXT NOT NULL,
  sent_at          TIMESTAMPTZ DEFAULT now(),
  is_read          BOOLEAN DEFAULT false
);

-- Alerts
CREATE TABLE alerts (
  alert_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  UUID REFERENCES patients(patient_id) ON DELETE CASCADE,
  type        TEXT NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  severity    TEXT CHECK (severity IN ('info','warning','critical')) DEFAULT 'info',
  created_at  TIMESTAMPTZ DEFAULT now(),
  is_read     BOOLEAN DEFAULT false
);

-- Device Tokens (push notifications)
CREATE TABLE device_tokens (
  token_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  UUID REFERENCES patients(patient_id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    TEXT CHECK (platform IN ('android','ios')),
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Clinics (enrichment over OSM data)
CREATE TABLE clinics (
  clinic_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  osm_id                   TEXT UNIQUE,
  name                     TEXT NOT NULL,
  phone                    TEXT,
  email                    TEXT,
  website                  TEXT,
  standard_checkup_price   DOUBLE PRECISION,
  currency                 TEXT DEFAULT 'USD',
  accepted_specialties     TEXT[],
  average_wait_minutes     INT,
  rating                   DOUBLE PRECISION,
  review_count             INT DEFAULT 0,
  is_network_partner       BOOLEAN DEFAULT false,
  opening_hours_json       JSONB
);
```

---

## 13. Global Data Type Reference

This table cross-references every Dart type used in the app's model layer to its SQL equivalent and JSON wire type, ensuring the back-end, database, and Flutter client stay in sync.

| Concept | Dart type | JSON wire type | PostgreSQL type |
|---|---|---|---|
| Primary / foreign key | `String` | `string (UUID v4)` | `UUID` |
| User-facing name | `String` | `string` | `TEXT` |
| URL (image, website) | `String` | `string (URL)` | `TEXT` |
| Eye pressure value | `double` | `number` | `DOUBLE PRECISION` |
| Date only | `String (ISO 8601)` | `string "YYYY-MM-DD"` | `DATE` |
| Date + time | `String (ISO 8601)` | `string "YYYY-MM-DDTHH:MM:SSZ"` | `TIMESTAMPTZ` |
| GPS coordinate | `double` | `number` | `DOUBLE PRECISION` |
| Distance (metres) | `double` | `number` | `DOUBLE PRECISION` |
| Enum / status | `String` | `string` | `TEXT + CHECK constraint` |
| Percentage | `double` (0–100) | `number` | `DOUBLE PRECISION` |
| Boolean flag | `bool` | `boolean` | `BOOLEAN` |
| Integer count | `int` | `number (integer)` | `INT` |
| Free text / notes | `String?` | `string \| null` | `TEXT` (nullable) |
| Tags / specialties | `List<String>` | `array of string` | `TEXT[]` |
| Opening hours | `Map<String, Map?>` | `object` | `JSONB` |
| Pagination offset | `int` | `number (integer)` | — (query param only) |
| JWT token | `String` | `string` | `TEXT` (refresh tokens table) |

---

*Last updated: May 30, 2026 — reflects Eye Resolve Flutter app v1.0 (main.dart)*
