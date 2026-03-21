# Technical Architecture — Preschool Communication Platform

**Version:** 1.0
**Date:** 2026-03-20
**Status:** Draft for founder review
**Scope:** V1 architecture through Year 3 scale (~500 schools, ~60,000 children)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Tech Stack Recommendation](#2-tech-stack-recommendation)
3. [Data Model](#3-data-model)
4. [GDPR / LOPDGDD Compliance Architecture](#4-gdpr--lopdgdd-compliance-architecture)
5. [Offline Architecture](#5-offline-architecture)
6. [Multi-tenant Architecture](#6-multi-tenant-architecture)
7. [Security Considerations](#7-security-considerations)
8. [Scalability Path](#8-scalability-path)
9. [Development Roadmap (Technical)](#9-development-roadmap-technical)
10. [Third-Party Services](#10-third-party-services)

---

## 1. Architecture Overview

### 1.1 High-Level System Diagram

```
                          ┌─────────────────────────────────────────────┐
                          │            EU-Hosted Infrastructure          │
                          │              (Fly.io / Frankfurt)             │
                          │                                               │
  ┌──────────────┐        │  ┌─────────────┐      ┌──────────────────┐  │
  │  Teacher App  │◄──────┼──►   API Server │      │  Background Jobs  │  │
  │  (React Native│  HTTPS│  │  (Elixir /  │      │  (Oban workers)  │  │
  │   + Expo)     │       │  │  Phoenix)   │◄─────►  - Media process │  │
  └──────────────┘        │  │             │      │  - Notifications  │  │
                          │  │  REST + WS  │      │  - Retention/del  │  │
  ┌──────────────┐        │  └──────┬──────┘      │  - Audit flush    │  │
  │  Parent App   │◄──────┼─────────┤             └──────────────────┘  │
  │  (React Native│  HTTPS│         │                                     │
  │   + Expo)     │       │  ┌──────▼──────┐      ┌──────────────────┐  │
  └──────────────┘        │  │ PostgreSQL   │      │     Redis         │  │
                          │  │ (primary DB) │      │  (sessions,       │  │
  ┌──────────────┐        │  │  Row-level   │      │   pub/sub,        │  │
  │  Web App      │◄──────┼──►  security    │      │   rate limits,    │  │
  │  (Next.js)    │  HTTPS│  │  per tenant  │      │   offline queue)  │  │
  └──────────────┘        │  └─────────────┘      └──────────────────┘  │
                          │                                               │
                          │  ┌───────────────────────────────────────┐   │
                          │  │  Tigris / Cloudflare R2 (EU bucket)   │   │
                          │  │  Media storage — photos, videos        │   │
                          │  │  Signed URL access, per-child ACL     │   │
                          │  └───────────────────────────────────────┘   │
                          └─────────────────────────────────────────────┘
                                            │
                          ┌─────────────────▼────────────────────────────┐
                          │              External Services                 │
                          │  Firebase FCM (push) · Brevo (email)          │
                          │  Vonage (SMS) · Sentry (errors)               │
                          │  Stripe (payments, SEPA)                      │
                          └──────────────────────────────────────────────┘
```

### 1.2 Architectural Philosophy

This is a **modular monolith** — a single deployable application with clearly separated internal modules, not microservices. This is the correct choice for a solo technical founder for these reasons:

- **Operational complexity kills early-stage startups.** Microservices require distributed tracing, service meshes, and polyglot deployments. One engineer cannot operate this effectively.
- **The domain boundaries are not yet proven.** You do not have enough real-world usage to know where the seams should be. A modular monolith lets you split later with confidence.
- **At Year 3 scale (500 schools, 60,000 children), a single Elixir node handles this comfortably.** This is not a high-throughput system. It is a data-privacy-sensitive, moderate-concurrency system.
- **Elixir's OTP process model gives you microservice-like isolation within a monolith** — each module has its own supervision tree, message passing, and fault isolation without network hops.

The monolith is NOT a compromise. It is the deliberate architecture for this scale and team size.

### 1.3 Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Backend runtime | Elixir / Phoenix | Concurrency, WebSockets at scale, fault tolerance, EU ecosystem |
| Mobile | React Native + Expo | Single codebase, offline support, large ecosystem, Expo EAS for OTA |
| Frontend web | Next.js (React) | Code sharing with mobile, SSR for SEO, strong ecosystem |
| Database | PostgreSQL (single cluster) | Row-level security for tenant isolation, JSONB for flexible activity logs |
| Real-time | Phoenix Channels (WebSockets) | Built into Phoenix, scales well, no third-party dependency |
| Media storage | Tigris (S3-compatible, EU) | S3-compatible API, EU data residency, no egress fees |
| Auth | JWT + refresh tokens | Stateless, works offline, mobile-friendly |
| Hosting | Fly.io (Frankfurt) | EU residency, simple deployment, Postgres managed option |

### 1.4 What We Are NOT Building in V1

| Deferred Feature | Why |
|------------------|-----|
| Separate microservices | Team size does not support the operational overhead |
| Custom video transcoding pipeline | Use a managed service (Mux or similar EU option) |
| In-app payments / billing UI | Stripe's hosted pages are sufficient for V1 |
| Analytics dashboard for schools | Deferred to V2 after validating core workflows |
| AI-generated activity summaries | Premature optimization before product-market fit |
| Parent-to-parent messaging | Out of scope and adds moderation complexity |
| Calendar / events module | V2 |
| Custom report builder | V2 |
| API for third-party integrations | V2 |

---

## 2. Tech Stack Recommendation

### 2.1 Backend: Elixir + Phoenix Framework

**Use Elixir with Phoenix 1.7+ and LiveView (for admin).**

Elixir runs on the BEAM VM, the same runtime as Erlang, which was designed for telecoms reliability (nine nines uptime). For a school communication app where parents rely on receiving attendance alerts and where WebSocket connections must stay open for real-time messaging, BEAM is the right runtime.

Specific reasons:

- Phoenix Channels (WebSockets) are first-class. You do not need a separate WebSocket server or a service like Pusher. One Phoenix node handles hundreds of thousands of concurrent WebSocket connections.
- Elixir processes are isolated. A crash in the messaging module does not crash the media upload module. OTP supervisors restart crashed processes automatically.
- Oban (background job library for Elixir) uses PostgreSQL as its queue — no Redis dependency for job processing, and jobs survive restarts with ACID guarantees.
- The ecosystem has excellent GDPR tooling: Cloak for field-level encryption, Ecto for safe database access with compile-time query checking.

The trade-off: Elixir has a smaller hiring pool than Node.js or Python. At 1-2 engineers this does not matter — you are the team. By the time you hire, you will have proven product-market fit and can afford to be selective.

**Internal module structure (enforced by Elixir's `use Boundary` or simply by convention):**

```
lib/
  preschool_app/
    accounts/          # Auth, users, roles
    schools/           # Tenant management, school settings
    children/          # Child profiles, parent-child links
    messaging/         # Direct messages, broadcasts
    daily_reports/     # Activity logs, meal/nap/mood
    attendance/        # Attendance records, alerts
    media/             # Photo/video upload, consent enforcement
    consent/           # GDPR consent records
    notifications/     # Push, email, SMS dispatch
    audit/             # Audit event logging
    gdpr/              # Retention policies, erasure requests
  preschool_app_web/   # Phoenix controllers, channels, views
```

Each top-level module owns its schemas, contexts, and business logic. Cross-module calls go through public context functions only — never direct schema access across modules.

### 2.2 Database: PostgreSQL 16

**Use PostgreSQL as the single primary datastore. Add Redis for caching and pub/sub.**

PostgreSQL is the correct choice because:

- **Row-Level Security (RLS)** enforces tenant isolation at the database level, not just application level. Even if application code has a bug, a parent from school A cannot read data from school B.
- **JSONB** columns handle the variable structure of daily activity logs (each school may configure different fields in the future) without sacrificing queryability.
- **Full-text search** in Spanish is built-in with proper dictionary support — you can search message history without Elasticsearch.
- **Audit triggers** can capture all mutations to sensitive tables directly in Postgres before they reach the application layer.
- **Ecto** (Elixir's database library) has first-class PostgreSQL support including RLS, LISTEN/NOTIFY, and array types.

Redis (via Fly.io Redis or Upstash EU) for:
- Session data and rate limiting counters
- Phoenix PubSub adapter for multi-node deployments
- Temporary offline sync queue state

Do NOT use Redis for anything that must survive a restart. Use PostgreSQL (via Oban) for durable queues.

### 2.3 Mobile: React Native + Expo (Managed Workflow)

**Use React Native with Expo SDK (managed workflow) for both iOS and Android.**

This is the right choice for a solo technical founder because:

- **Single codebase** for iOS and Android. You cannot afford to maintain two native codebases.
- **Expo EAS (Expo Application Services)** provides over-the-air (OTA) updates via EAS Update — critical for pushing bug fixes to teachers without waiting for App Store review.
- **Expo EAS Build** handles iOS/Android builds in CI without requiring a Mac for Android builds.
- **WatermelonDB** (React Native SQLite wrapper) provides the offline-first database layer with lazy loading and sync primitives — exactly what you need for offline daily reports.
- **React Native's ecosystem** for this use case (camera, file system, push notifications via Expo Notifications) is mature and well-documented.

The trade-off versus Flutter: Flutter has better performance on low-end Android devices. However, React Native with the New Architecture (Fabric renderer, JSI) is now competitive, and sharing code and engineers with the Next.js web frontend has compounding value. Expo's ecosystem for push notifications and OTA updates is ahead of FlutterFire for this specific feature set.

Do NOT use the Expo Go development client in production. Use Expo's Development Client with a custom native build from the start — you will need the native SQLite and camera modules anyway.

### 2.4 Web Frontend: Next.js 15 (App Router)

**Use Next.js with the App Router for the web application.**

The web app serves two distinct purposes:

1. **Teacher/director portal** — daily report entry (also available on mobile, but some directors prefer desktop for administrative tasks like managing class rosters)
2. **Parent portal** — viewing reports, photos, messages (many parents will use the app, but having a web fallback is good for accessibility and older device compatibility)

Next.js reasons:
- Server-side rendering improves perceived performance for parents loading photo galleries on mobile browsers.
- React component library can be shared (or conceptually aligned) with React Native components.
- Next.js API routes can serve as a lightweight BFF (Backend for Frontend) layer if needed — though most API calls go directly to the Phoenix backend.
- Vercel EU region deployment is available and easy to set up, but since we're already on Fly.io, we can deploy Next.js as a Fly.io app in Frankfurt.

### 2.5 Real-Time / Messaging: Phoenix Channels

**Use Phoenix Channels (WebSockets) built into the Phoenix framework. Do not use a third-party service like Pusher or Ably.**

Phoenix Channels are production-proven, handle millions of concurrent connections, and are free. The alternative (Pusher/Ably) costs money at scale and creates a GDPR dependency on a third-party processor for message content.

Message delivery architecture:
- Each teacher and parent connects to a Phoenix Channel on app open, subscribing to their relevant topics (school-specific, class-specific, child-specific).
- Messages are persisted to PostgreSQL first, then broadcast via Phoenix PubSub.
- Push notifications (FCM/APNs) are sent for users who are not currently connected — handled by an Oban background job triggered after message persistence.
- If WebSocket connection drops, the client reconnects and fetches missed messages via REST API using a `since` timestamp parameter.

### 2.6 Push Notifications: Firebase Cloud Messaging (FCM) + APNs via FCM

**Use Firebase Cloud Messaging for both Android and iOS push notifications.**

FCM handles both Android native push and iOS APNs via a single API. Expo's push notification service wraps FCM and APNs in a single endpoint (`https://exp.host/--/api/v2/push/send`) which handles token management, retry, and receipt checking.

Use **Expo Push Notifications** as the abstraction layer in V1 — it simplifies token management across iOS and Android. This creates a dependency on Expo's servers (US-hosted) for the push notification routing layer. This is acceptable because:

1. Push notification payloads should never contain sensitive child data — only "You have a new message" type content.
2. The actual content is fetched from your EU-hosted API when the parent opens the notification.
3. Expo's push service is GDPR-compatible as a processor when configured correctly (minimal data, device tokens only).

If this becomes a concern at scale, migrate to direct FCM/APNs integration — but do not optimize this in V1.

### 2.7 Media Storage: Tigris (S3-Compatible, EU)

**Use Tigris for photo and video storage.**

Tigris is an S3-compatible object storage provider with native Fly.io integration, EU data residency (Frankfurt), and no egress fees when accessed from Fly.io apps. It supports:

- Presigned upload URLs (client uploads directly to Tigris, bypassing your server)
- Presigned download URLs with expiry (enforcing per-child access control)
- Automatic replication within the EU

Access control model:
- Media is stored with opaque, unguessable keys (UUID v4, not child names or school names)
- Download access is controlled exclusively through server-generated signed URLs with 15-minute expiry
- The server checks consent and family relationship before generating a signed URL
- Public access on the bucket is disabled — no object is ever publicly accessible

For video: store the original upload. Use a background Oban job to transcode to H.264/AAC MP4 using `ffmpeg` running on the server for V1. At Year 3 scale, evaluate moving to a managed transcoding service. Do NOT use Mux in V1 — it is US-based and overkill for 60-second videos at this scale.

### 2.8 Auth: JWT + Refresh Tokens (via Guardian)

**Use Guardian (Elixir JWT library) with short-lived access tokens and long-lived refresh tokens stored in HttpOnly cookies for web, and in secure device storage for mobile.**

Token strategy:
- Access token: 15-minute expiry, signed JWT, contains `user_id`, `school_id`, `role`
- Refresh token: 30-day expiry, stored in PostgreSQL (allows server-side revocation), rotated on each refresh

Three user roles are encoded in the JWT:
- `director` — full access to their school's data
- `teacher` — access to assigned classrooms
- `parent` — access only to their own children's data

Role-based access is enforced at the Phoenix controller level using `plug` pipelines, not in the frontend.

Do NOT use a third-party auth service (Auth0, Clerk) for V1 for two reasons: (1) they add a GDPR third-party dependency for user identity data, and (2) Guardian is mature, well-understood, and gives you full control over token revocation and session management.

### 2.9 Hosting / Infrastructure: Fly.io (Frankfurt Region)

**Deploy everything on Fly.io in the `fra` (Frankfurt) region for EU data residency.**

Fly.io advantages for this use case:
- Native Elixir/BEAM support with built-in clustering — Elixir nodes can form a cluster automatically via Fly.io's internal DNS, enabling Phoenix PubSub across multiple nodes without configuration.
- Managed PostgreSQL (Fly Postgres) in Frankfurt — or use Supabase EU (Frankfurt) for a more managed experience with built-in connection pooling (PgBouncer).
- Simple deployment model — `fly deploy` from CI. No Kubernetes, no ECS task definitions.
- Private networking between services (no public internet between app and database).
- Reasonable cost at this scale — a 2-node app cluster + managed Postgres + Redis starts under €100/month.

Use **Supabase (EU Frankfurt region)** for PostgreSQL over Fly Postgres for these reasons:
- Built-in PgBouncer connection pooling (critical for Elixir's many short-lived DB connections)
- Point-in-time recovery out of the box
- Easy database migrations with a web UI (useful when you're the sole engineer)
- Row-Level Security tooling in the Supabase dashboard

Supabase's EU Frankfurt region stores all data in Frankfurt. Their DPA (Data Processing Agreement) is GDPR-compliant.

**Infrastructure as Code:** Use Fly.io's `fly.toml` for app configuration and keep it in the repository. Do NOT use Terraform in V1 — the infrastructure is simple enough that `fly.toml` + Supabase dashboard is sufficient.

### 2.10 CI/CD: GitHub Actions

**Use GitHub Actions for CI/CD.**

Pipeline stages:
1. `test` — run Elixir ExUnit tests + mix credo (linting) + mix dialyzer (type checking)
2. `build` — Docker image build + push to Fly.io registry
3. `deploy` — `fly deploy` to production (on merge to `main`, after tests pass)
4. `mobile` — Expo EAS Build triggered on tagged releases

Keep it simple: no staging environment in V1. Use feature flags (a simple `feature_flags` table in PostgreSQL) to gate incomplete features in production. This is faster than maintaining two environments as a solo engineer.

---

## 3. Data Model

### 3.1 Entity Overview and Relationships

```
School (tenant)
  ├── has many Classrooms
  ├── has many Staff
  ├── has many Children
  └── has many RetentionPolicies

Classroom
  ├── belongs to School
  ├── has many Children (through ClassroomEnrollment)
  └── has many Staff (through ClassroomAssignment)

Child
  ├── belongs to School
  ├── has many ParentChildLinks
  ├── has one or many ConsentRecords
  ├── has many AttendanceRecords
  └── has many MediaTags

Staff
  ├── belongs to School
  ├── has one User
  └── role: director | teacher | admin

Parent (Guardian)
  ├── has one User
  ├── has many ParentChildLinks
  └── has many NotificationPreferences

User (authentication identity)
  ├── polymorphic: belongs to Staff OR Parent
  └── has many RefreshTokens

DailyReport
  ├── belongs to Classroom
  ├── created_by Staff
  ├── has many ActivityLogEntries (per-child overrides)
  └── has many Media

ActivityLogEntry
  ├── belongs to DailyReport
  ├── optionally scoped to Child (nil = class-level default)
  ├── meal_status, nap_minutes, mood, free_text
  └── completed_at

Message
  ├── belongs to School
  ├── sent_by Staff (or parent for direct replies)
  ├── type: direct | class_broadcast | school_broadcast
  ├── target: parent_id | classroom_id | school_id
  └── has many MessageReceipts

Media
  ├── belongs to School
  ├── belongs to DailyReport (nullable — media can be standalone)
  ├── uploaded_by Staff
  ├── type: photo | video
  ├── storage_key (opaque UUID in Tigris)
  ├── has many MediaTags (child_id + consent_verified_at)
  └── processing_status: pending | ready | failed

ConsentRecord
  ├── belongs to Child
  ├── belongs to Parent (who gave consent)
  ├── consent_type: photo | video | data_processing | etc.
  ├── status: granted | revoked
  ├── granted_at, revoked_at
  └── ip_address, user_agent (for audit)

AttendanceRecord
  ├── belongs to Child
  ├── belongs to Classroom
  ├── date
  ├── status: present | absent | late
  ├── absence_reason (nullable)
  ├── parent_notified_at (nullable)
  └── safeguarding_alerted_at (nullable)

AuditEvent
  ├── school_id (tenant)
  ├── actor_id, actor_type
  ├── event_type (string enum)
  ├── resource_type, resource_id
  ├── metadata (JSONB)
  └── occurred_at
```

### 3.2 Core Entity Field Definitions

#### School (Tenant)

```sql
CREATE TABLE schools (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  slug            TEXT NOT NULL UNIQUE,           -- URL identifier
  locale          TEXT NOT NULL DEFAULT 'es',     -- primary language
  timezone        TEXT NOT NULL DEFAULT 'Europe/Madrid',
  address         JSONB,                          -- structured address
  subscription_status TEXT NOT NULL DEFAULT 'trial',  -- trial | active | suspended | cancelled
  subscription_tier   TEXT NOT NULL DEFAULT 'basic',
  stripe_customer_id  TEXT,
  data_retention_days INTEGER NOT NULL DEFAULT 365,   -- GDPR configurable
  safeguarding_alert_hour INTEGER NOT NULL DEFAULT 10, -- 10:00 AM by default
  settings        JSONB NOT NULL DEFAULT '{}',    -- school-specific config
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ                     -- soft delete
);
```

#### Child

```sql
CREATE TABLE children (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id),
  first_name      TEXT NOT NULL,
  last_name       TEXT NOT NULL,
  date_of_birth   DATE NOT NULL,
  classroom_id    UUID REFERENCES classrooms(id),
  avatar_media_id UUID REFERENCES media(id),      -- profile photo (separate consent)
  medical_notes   TEXT,                           -- GDPR: encrypted at field level
  dietary_notes   TEXT,                           -- GDPR: encrypted at field level
  active          BOOLEAN NOT NULL DEFAULT true,
  enrolled_at     DATE NOT NULL,
  left_at         DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Row-Level Security enforced: school_id must match current_setting('app.school_id')
```

#### ConsentRecord

```sql
CREATE TABLE consent_records (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id),
  child_id        UUID NOT NULL REFERENCES children(id),
  granted_by_user_id UUID NOT NULL REFERENCES users(id),
  consent_type    TEXT NOT NULL,                  -- 'photo_sharing' | 'video_sharing' | 'data_processing' | 'research'
  status          TEXT NOT NULL DEFAULT 'granted', -- 'granted' | 'revoked'
  granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at      TIMESTAMPTZ,
  revocation_reason TEXT,
  -- Audit fields for GDPR proof of consent
  ip_address      INET,
  user_agent      TEXT,
  consent_text_version TEXT NOT NULL,             -- version of the consent text shown
  -- Constraints
  UNIQUE (child_id, consent_type, granted_at)     -- one record per consent event
);
```

#### DailyReport

```sql
CREATE TABLE daily_reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id),
  classroom_id    UUID NOT NULL REFERENCES classrooms(id),
  report_date     DATE NOT NULL,
  created_by_id   UUID NOT NULL REFERENCES staff(id),
  published_at    TIMESTAMPTZ,                    -- null = draft, set = published and triggers notifications
  class_summary   TEXT,                           -- default activity description for all children
  class_meal_status TEXT,                         -- 'good' | 'partial' | 'poor'
  class_nap_minutes INTEGER,
  class_mood      TEXT,                           -- 'happy' | 'calm' | 'tired' | 'difficult'
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (classroom_id, report_date)              -- one report per class per day
);
```

#### ActivityLogEntry (per-child override)

```sql
CREATE TABLE activity_log_entries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id),
  daily_report_id UUID NOT NULL REFERENCES daily_reports(id),
  child_id        UUID NOT NULL REFERENCES children(id),
  -- Overrides: null means "inherit from class-level report"
  meal_status     TEXT,
  nap_minutes     INTEGER,
  mood            TEXT,
  notes           TEXT,                           -- private teacher notes, not shown to parents
  parent_message  TEXT,                           -- shown to parent in their child's view
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (daily_report_id, child_id)
);
```

#### Media

```sql
CREATE TABLE media (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id),
  daily_report_id UUID REFERENCES daily_reports(id),
  uploaded_by_id  UUID NOT NULL REFERENCES staff(id),
  type            TEXT NOT NULL,                  -- 'photo' | 'video'
  storage_key     TEXT NOT NULL UNIQUE,           -- opaque UUID key in Tigris
  original_filename TEXT,                         -- stored for audit, not used in URLs
  file_size_bytes BIGINT,
  duration_seconds INTEGER,                       -- for video only
  processing_status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'ready' | 'failed'
  taken_at        TIMESTAMPTZ,                    -- EXIF or client-reported capture time
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE media_child_tags (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  media_id        UUID NOT NULL REFERENCES media(id),
  child_id        UUID NOT NULL REFERENCES children(id),
  school_id       UUID NOT NULL REFERENCES schools(id),
  tagged_by_id    UUID NOT NULL REFERENCES staff(id),
  consent_verified_at TIMESTAMPTZ NOT NULL,       -- timestamp consent was checked
  consent_record_id   UUID NOT NULL REFERENCES consent_records(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (media_id, child_id)
);
```

**Critical constraint:** A `media_child_tags` row cannot be inserted unless a valid `consent_records` row exists for the child with `consent_type = 'photo_sharing'` and `status = 'granted'`. This is enforced via a PostgreSQL trigger and in the Elixir application layer (defense in depth).

#### Message

```sql
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id),
  sender_id       UUID NOT NULL REFERENCES users(id),
  thread_id       UUID,                           -- null for new thread, set for replies
  type            TEXT NOT NULL,                  -- 'direct' | 'class_broadcast' | 'school_broadcast'
  -- Target (exactly one must be set based on type)
  target_user_id      UUID REFERENCES users(id),     -- for direct
  target_classroom_id UUID REFERENCES classrooms(id), -- for class_broadcast
  -- target_school_id is implicit (school_id) for school_broadcast
  body            TEXT NOT NULL,
  sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- GDPR: auto-delete after retention period
  delete_after    TIMESTAMPTZ NOT NULL,           -- computed from school retention policy
  deleted_at      TIMESTAMPTZ,                    -- soft delete for immediate erasure requests
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE message_receipts (
  message_id      UUID NOT NULL REFERENCES messages(id),
  user_id         UUID NOT NULL REFERENCES users(id),
  delivered_at    TIMESTAMPTZ,
  read_at         TIMESTAMPTZ,
  PRIMARY KEY (message_id, user_id)
);
```

#### AuditEvent

```sql
CREATE TABLE audit_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id),
  occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  actor_id        UUID,                           -- null for system events
  actor_type      TEXT,                           -- 'staff' | 'parent' | 'system'
  event_type      TEXT NOT NULL,                  -- see event catalog below
  resource_type   TEXT,
  resource_id     UUID,
  metadata        JSONB NOT NULL DEFAULT '{}',
  ip_address      INET,
  user_agent      TEXT
) PARTITION BY RANGE (occurred_at);              -- partition by month for retention management
```

**Audit event catalog (non-exhaustive):**

| Event Type | Triggered By |
|-----------|-------------|
| `user.login` | Any login |
| `user.logout` | Explicit logout |
| `media.viewed` | Signed URL generated for parent |
| `media.uploaded` | Teacher uploads photo/video |
| `child.tagged` | Child tagged in media |
| `consent.granted` | Parent gives consent |
| `consent.revoked` | Parent revokes consent |
| `report.published` | Teacher publishes daily report |
| `message.sent` | Any message sent |
| `attendance.marked` | Teacher marks attendance |
| `safeguarding.alert` | Safeguarding alert triggered |
| `gdpr.erasure_request` | Parent requests data deletion |
| `gdpr.erasure_completed` | Erasure job completes |
| `data.exported` | Data export requested |

---

## 4. GDPR / LOPDGDD Compliance Architecture

### 4.1 Data Residency

All data — user accounts, messages, photos, videos, audit logs — resides in the EU at all times.

| Component | Provider | Location |
|-----------|----------|----------|
| Application database | Supabase (PostgreSQL) | Frankfurt, Germany |
| Redis cache | Upstash | EU (Frankfurt) |
| Media storage | Tigris | EU (Frankfurt) |
| Application servers | Fly.io | Frankfurt, Germany |
| Email delivery | Brevo (EU-based) | EU |
| Push notification routing | Expo Push (proxied via own server) | See note below |

**Push notification note:** FCM infrastructure routes through Google's global network. The push notification payload must never contain personal data or message content — only a notification ID. The receiving device calls your EU-hosted API to fetch the actual content. This architecture means personal data never leaves the EU.

**Data Processing Agreements (DPAs) required with:**
- Supabase — available, signed at account level
- Fly.io — available on request
- Tigris — available (Fly.io subsidiary)
- Brevo — standard GDPR DPA included
- Stripe — standard DPA included

### 4.2 Consent Management

Consent is a first-class domain entity, not a checkbox in a settings table.

**Consent types:**
1. `data_processing` — required for the app to function (legal basis: contract)
2. `photo_sharing` — optional, allows tagging child in photos
3. `video_sharing` — optional, allows tagging child in videos
4. `research` — optional, anonymous usage data for product research

**Consent enforcement layers (defense in depth):**

Layer 1 — Application logic: Before creating a `media_child_tags` record, the `Media.Consent` module checks for a valid `consent_records` row.

Layer 2 — Database constraint: A PostgreSQL trigger on `media_child_tags` validates consent before insert.

Layer 3 — Signed URL generation: Before generating a signed download URL, the server re-checks the parent's relationship to the child AND the consent status. A revoked consent immediately invalidates future URL generation even for previously-tagged media.

**Consent UI requirements:**
- Consent must be collected via an explicit, unambiguous action (checkbox, not pre-ticked).
- Consent text version must be stored with the consent record — if the consent text changes, existing consents must be renewed.
- Parents can view and revoke consent at any time from the app.
- Consent events are written to the audit log.

### 4.3 Photo Visibility Enforcement

Server-side enforcement is non-negotiable. The client NEVER makes visibility decisions.

```
Parent requests photo → Server checks:
  1. Is parent authenticated? (JWT validation)
  2. Does parent have a ParentChildLink for at least one tagged child? (DB query)
  3. Does that child have an active photo consent? (consent check)
  4. Is the media not deleted? (soft delete check)
  → If all pass: generate 15-minute presigned URL from Tigris
  → If any fail: 403 Forbidden (never 404, which leaks existence)
```

The Tigris bucket has zero public access. Every photo URL is a time-limited signed URL. There is no URL a parent can "share" that will work after 15 minutes.

**Photo tagging UI constraint:** The teacher's tagging interface must only show children for whom photo consent exists. This is a UX safeguard — the server enforces it regardless.

### 4.4 Data Retention and Auto-Delete

Each school configures a `data_retention_days` value (default 365 days, minimum 90 days to comply with reasonable operational needs, maximum configurable per contract).

Implementation via Oban scheduled job (runs nightly at 02:00 EU time):

```
RetentionJob:
  1. Find all messages where delete_after < now() AND deleted_at IS NULL
     → Soft delete, wipe body content, log audit event
  2. Find all media where created_at < (now() - retention_days) AND deleted_at IS NULL
     → Remove from Tigris, soft delete DB record, wipe storage_key
  3. Find all daily_reports outside retention window
     → Archive ActivityLogEntries (aggregate stats only), delete raw entries
  4. Find all audit_events outside legal minimum retention (5 years for LOPDGDD)
     → These are NEVER deleted within legal minimums, but can be archived to cold storage
```

Messages are soft-deleted first (body set to null, deleted_at set). Hard delete of the row happens 30 days later, giving a recovery window for operational mistakes.

### 4.5 Right to Erasure (GDPR Article 17)

A parent can request deletion of their personal data and their child's data. This is a complex operation that must be handled carefully.

**Erasure scope for a parent:**
- User account and profile
- All messages they sent (body content redacted, metadata retained for thread integrity)
- All message receipts
- All consent records (marked as revoked, not deleted — legal requirement to retain evidence of past consent for audit)
- Notification preferences
- Device tokens

**Erasure scope for a child (requested by parent with parental authority):**
- All media tags for the child
- All activity log entries with per-child data
- All attendance records
- The child profile (anonymized, not hard-deleted — retained as an enrollment count record)
- All media exclusively tagged to this child (deleted from Tigris)

**What is NOT deleted (legal retention obligations):**
- Audit events (minimum 5 years per LOPDGDD)
- Anonymized attendance statistics (no PII, used for school billing)
- Invoice and payment records (7 years, Spanish tax law)

Implementation: Erasure requests create an `ErasureRequest` record with status `pending`. An Oban job processes them asynchronously within 30 days (GDPR requirement) and sends a completion notification. All erasure completions are logged in the audit trail.

### 4.6 Encryption

**In transit:** TLS 1.3 mandatory for all connections. HSTS enforced. Fly.io handles TLS termination at the edge.

**At rest:**
- Database: Supabase (PostgreSQL) encrypts the storage volume at rest (AES-256). This is infrastructure-level encryption.
- Media: Tigris encrypts all objects at rest (AES-256).
- Field-level encryption: Use Cloak (Elixir library) to encrypt sensitive fields before they reach the database. Fields requiring field-level encryption:
  - `children.medical_notes`
  - `children.dietary_notes`
  - `users.phone_number`
  - `consent_records.ip_address`

Field-level encryption means even a database dump does not expose these values without the application's encryption key.

**Encryption key management:** Store encryption keys in environment variables (Fly.io secrets), not in the database. Rotate keys annually using Cloak's key rotation support.

### 4.7 DPO Support

A Data Protection Officer (if the school is large enough to require one, or if you appoint one voluntarily) needs the following capabilities, all of which the system must support:

- **Data subject access request (DSAR) export:** The system can generate a structured JSON export of all personal data for a given parent or child, including audit trail of who accessed their data.
- **Consent dashboard:** A read-only view showing all consents granted/revoked per child per school.
- **Retention policy audit:** A report showing when data is scheduled for deletion and what has been deleted.
- **Processing activity record (Article 30 record):** The system generates a machine-readable list of all data categories processed, their legal basis, and retention periods — suitable for inclusion in the school's ROPA.
- **Breach notification support:** Audit logs provide the data needed to determine the scope of a breach and notify the AEPD (Spanish data protection authority) within 72 hours.

---

## 5. Offline Architecture

### 5.1 Offline Feature Scope

| Feature | Offline Support | Rationale |
|---------|----------------|-----------|
| Daily report entry | Full offline | Primary use case for offline |
| Photo capture and tagging | Capture offline, sync when online | Teacher in garden, poor WiFi |
| Video capture | Capture offline, sync when online | Same as photos |
| Attendance marking | Full offline | Morning routine, unreliable network |
| Messaging (compose) | Queue offline, send when online | Teacher can draft messages |
| Messaging (receive) | Read cached messages only | Cannot receive new messages offline |
| Class roster viewing | Read cached data | Needed to know who is in class |
| Push notifications | Not available offline | By definition requires connectivity |

### 5.2 Client-Side Storage

**Use WatermelonDB for React Native (mobile) and IndexedDB via Dexie.js for the web app.**

WatermelonDB is built on SQLite (via Expo SQLite) and is designed specifically for React Native offline-first apps. Its key feature is lazy loading — it does not load all records into memory, making it performant on mid-range Android devices.

Local schema (mobile):

```
LocalDailyReport    — mirrors server DailyReport + sync metadata
LocalActivityEntry  — per-child overrides
LocalAttendance     — attendance records
LocalChild          — class roster (cached at login/refresh)
LocalMessage        — last 30 days of messages
LocalMedia          — pending uploads (path to local file + metadata)
SyncState           — last sync timestamp per resource type
```

Each local record has:
- `server_id` — UUID from server (null until synced)
- `local_id` — UUID generated on device
- `sync_status` — `synced | pending | conflict | error`
- `created_locally_at` — device timestamp
- `updated_locally_at` — device timestamp

### 5.3 Sync Strategy

**Strategy: Last-write-wins with conflict detection, server is authoritative.**

Sync runs automatically when network connectivity is detected (via `NetInfo` from `@react-native-community/netinfo`). Manual sync is also available via pull-to-refresh.

Sync protocol:

```
1. PULL: GET /api/v1/sync?since={last_sync_timestamp}&resources=children,classrooms,messages
   → Server returns all changes since last sync
   → Client merges, preferring server data for shared resources (class rosters, published reports)

2. PUSH: POST /api/v1/sync/push
   → Client sends all records with sync_status = 'pending'
   → Payload: array of { local_id, resource_type, operation, data, client_timestamp }

3. CONFLICT RESOLUTION:
   → For daily reports: if a published report exists on server, client draft is marked 'conflict'
     Teacher is shown both versions and can choose or merge
   → For attendance: server wins if record already exists (prevents double-marking)
   → For media uploads: always accepted as new records (media is additive)

4. RECEIPT: Server returns { local_id → server_id } mapping for all accepted records
   → Client updates local records with server_id and sync_status = 'synced'
```

The `since` parameter uses server-side timestamps (not client timestamps) to avoid clock skew issues. The server records `updated_at` on every mutation.

### 5.4 Media Offline Handling

Photos and videos captured offline are stored in the device's local file system (via `expo-file-system`) with a reference in the local WatermelonDB `LocalMedia` table.

When connectivity returns, a background upload job:
1. Requests a presigned upload URL from the server (POST `/api/v1/media/presign`)
2. Uploads directly to Tigris using the presigned URL
3. Notifies the server of completed upload (POST `/api/v1/media/{id}/uploaded`)
4. Updates the local record's `sync_status` to `synced`

Offline photo tagging: the teacher can tag children from the local roster cache. When synced, the server re-validates consent for each tag before persisting. If consent was revoked between offline capture and sync, the tag is rejected and the teacher is notified.

**GDPR implication:** Photos stored locally on a teacher's device before sync represent a temporary local copy outside your infrastructure. This is unavoidable for offline functionality but must be addressed in:
- The school's data processing policy (teachers must not transfer work device photos to personal devices)
- The app's terms of use (offline data is not backed up until synced, teacher accepts responsibility)
- Local photos are deleted from device storage after successful sync (configurable, but default ON)

---

## 6. Multi-tenant Architecture

### 6.1 Tenant Isolation Model

**Use a shared PostgreSQL database with Row-Level Security (RLS) enforced per tenant.**

The alternatives and why they are wrong for this scale:

- **Separate database per school:** Management overhead is unacceptable for 500 schools. Schema migrations become a distributed systems problem. Database connection limits become a bottleneck.
- **Separate schema per school:** Better isolation but migrations still require iteration over all schemas. Monitoring and querying across tenants is difficult. Schema count grows linearly.
- **Shared tables with `school_id` column + RLS:** Correct choice. Single migration path, centralized monitoring, PostgreSQL enforces isolation at the row level even if application code has a bug.

**RLS Implementation:**

```sql
-- Set at the start of every DB connection from Phoenix
SET LOCAL app.school_id = '<uuid>';

-- Policy on every tenant-scoped table:
CREATE POLICY tenant_isolation ON children
  USING (school_id = current_setting('app.school_id')::UUID);
```

The Phoenix application sets `app.school_id` from the authenticated JWT before any database query. The RLS policy ensures no query can return rows from a different school.

**Superuser bypass:** A separate `admin` connection role (used only for migrations and internal tooling) bypasses RLS. This role is never used by the application runtime — only by maintenance scripts.

### 6.2 Cross-Tenant Data

There is no cross-tenant data in this application. Schools are fully isolated. The only shared infrastructure is:
- The application code itself
- The Postgres cluster (tenant-isolated via RLS)
- The Tigris bucket (isolated via key namespacing: `/{school_id}/{year}/{uuid}`)

School slugs (subdomains, if applicable) are globally unique but do not leak data — they are only used for routing.

### 6.3 New School Onboarding

Onboarding a new school is a transactional operation:

```
SchoolOnboarding transaction:
  1. Create School record (generates UUID, assigns slug)
  2. Create first Staff record with role: director
  3. Create User record linked to director Staff
  4. Send welcome email with password setup link
  5. Create default RetentionPolicy (365 days)
  6. Create default school Settings
  7. Log audit event: school.created
  8. Create Stripe Customer (async, non-blocking)
```

This is a single Elixir Ecto.Multi transaction — all steps succeed or all roll back. School setup is complete in under 1 second.

After onboarding, the director uses the web app to:
- Create classrooms
- Invite teachers (email invitation flow)
- Import or manually add children
- Configure safeguarding alert time

Child import: support CSV import (first name, last name, date of birth, classroom). The director uploads a CSV; a background job validates and creates Child records. Parent invitation emails are sent after child creation.

---

## 7. Security Considerations

### 7.1 Authentication

JWTs are signed with RS256 (asymmetric keys), not HS256. This matters because:
- The public key can be distributed to any service that needs to verify tokens
- Compromise of the verification key does not allow token forgery
- Key rotation is easier (new public key without invalidating old tokens during transition period)

Token storage:
- **Web:** Access token in memory (JavaScript variable), refresh token in HttpOnly + Secure + SameSite=Strict cookie. The access token is never stored in localStorage or sessionStorage — XSS attacks cannot steal it.
- **Mobile:** Both tokens stored in Expo SecureStore (iOS Keychain / Android Keystore). Never in AsyncStorage.

Session management:
- Refresh tokens stored in `refresh_tokens` table with `user_id`, `token_hash`, `expires_at`, `revoked_at`, `device_fingerprint`.
- Logging out invalidates the refresh token server-side.
- A director can see all active sessions for their account and revoke any of them.
- After 3 failed login attempts from the same IP, impose a 5-minute lockout. After 10, require CAPTCHA.

### 7.2 Authorization

Role hierarchy and permissions:

| Action | Director | Teacher | Parent |
|--------|---------|---------|--------|
| Manage school settings | Yes | No | No |
| Manage staff | Yes | No | No |
| Manage classrooms | Yes | No | No |
| Add/edit children | Yes | No | No |
| View any classroom's report | Yes | Own classrooms | No |
| Create daily report | Yes | Own classrooms | No |
| Upload media | Yes | Own classrooms | No |
| Tag children in media | Yes | Own classrooms (consent enforced) | No |
| View media | Yes (own school) | Own classrooms | Own children (consent required) |
| Send messages | Yes (any target) | Own classrooms | Reply to direct messages only |
| View attendance | Yes | Own classrooms | Own children |
| Mark attendance | Yes | Own classrooms | No |
| View/manage consent | Own school | No | Own children |
| Request data export | Yes (school data) | No | Own data |

Authorization is enforced in Phoenix controller plugs, not in the frontend. Every API endpoint checks the authenticated user's role and relationship to the requested resource before performing any database operation.

### 7.3 Media Access Security

```
GET /api/v1/media/{media_id}/url

1. Authenticate user (JWT)
2. Check user's role:
   a. Staff: is this media in their school? Are they assigned to the classroom?
   b. Parent: do they have a child tagged in this media? Is consent active?
3. Check media is not deleted
4. Generate Tigris presigned URL (15 minutes expiry)
5. Log audit event: media.viewed { media_id, user_id, timestamp }
6. Return { url, expires_at }
```

The client must re-request a URL after 15 minutes if the user is still viewing. This is intentional — it ensures access control is re-evaluated continuously.

Do NOT generate signed URLs client-side. The Tigris secret key must never leave the server.

### 7.4 API Security

- **Rate limiting:** 100 requests/minute per authenticated user, 10 requests/minute for unauthenticated login attempts. Enforced via Redis counter with sliding window.
- **Input validation:** All inputs validated with Ecto changesets before reaching business logic. Binary content type validation for media uploads.
- **SQL injection:** Impossible via Ecto parameterized queries. Never use string interpolation in database queries.
- **CORS:** Strict origin allowlist — only the known web frontend origin is permitted.
- **Content Security Policy:** Strict CSP headers on the web app. Media served from Tigris, not from the same origin.
- **Helmet headers:** X-Frame-Options: DENY, X-Content-Type-Options: nosniff, Referrer-Policy: no-referrer.

### 7.5 Child Data Protection

Beyond standard auth/authz:

- **Child profile photos (avatars) are treated as sensitive media** — same consent enforcement as activity photos.
- **Child names are never included in push notification payloads.** A notification reads "New daily report available" not "Maria's report is ready."
- **Child date of birth is not displayed in the parent app** — only age in years/months. Date of birth is stored but not surfaced unnecessarily.
- **Staff cannot access children outside their assigned classrooms** — a teacher assigned to Sala Girasoles cannot view records for Sala Margaritas.
- **Audit log for every access to child records** — if there is ever a safeguarding concern, you can produce a complete access log.

---

## 8. Scalability Path

### 8.1 What Works at 100 Schools, What Breaks at 500

**Works fine through Year 3 without changes:**
- Single PostgreSQL instance (Supabase scales to the required size easily)
- Single Elixir application (Elixir handles millions of concurrent WebSocket connections on one node)
- Tigris media storage (object storage is inherently scalable)
- Current data model and RLS approach

**What to monitor and potentially address at ~300 schools:**

1. **Database connection pooling:** Supabase's built-in PgBouncer handles this. If you add more Phoenix nodes, PgBouncer's pool may need tuning. This is a configuration change, not an architecture change.

2. **Audit log table growth:** The `audit_events` table grows linearly with usage. The monthly partition strategy means you can archive/drop old partitions without locking the table. Start archiving partitions older than 5 years to cold storage (S3 Glacier equivalent in EU).

3. **Media storage costs:** 500 schools × ~20 photos/day × 365 days × 3MB/photo = ~11TB/year. Tigris costs approximately €0.015/GB/month — about €165/month at this volume. Not a concern.

4. **Push notification throughput:** At 500 schools, a simultaneous daily report publish by all teachers at ~09:00 generates ~30,000 push notifications in a few minutes. Oban with 10-20 workers handles this. If needed, add a dedicated Oban queue for notifications with higher concurrency.

### 8.2 What to Defer to Phase 2

| Item | Why Defer |
|------|-----------|
| Read replicas | Not needed until query performance degrades. Supabase makes this one click when needed. |
| CDN for media | Tigris has edge caching built in. Only need a dedicated CDN if serving globally, which is not the plan. |
| Separate notification service | Oban handles V1 scale. Extract if notification volume warrants dedicated workers. |
| Full-text search service | PostgreSQL FTS handles Spanish text search adequately through Year 3. Elastic/Typesense deferred. |
| Event sourcing / CQRS | Premature for this domain. Add if reporting requirements become complex. |
| Separate read model for analytics | Deferred until you have a dashboard product to build. |

### 8.3 Database Scaling Path

```
V1 (now – Year 1):
  Supabase PostgreSQL, single instance, Frankfurt
  Connection pooling via PgBouncer (built-in)

V2 (Year 2–3):
  Add read replica for reporting queries
  Archive audit_events partitions > 2 years to cold storage

V3 (if needed, Year 4+):
  Evaluate vertical scaling (larger instance) before horizontal
  If horizontal: Citus for partitioning by school_id (transparent to application)
  At this point: re-evaluate if some schools are large enough to warrant dedicated schemas
```

The correct order is always: optimize queries first, add indexes second, scale vertically third, scale horizontally last. You are years away from needing horizontal database scaling.

---

## 9. Development Roadmap (Technical)

### 9.1 Critical Path to Shippable V1

The order matters. Build in this sequence to unblock everything else:

**Week 1–2: Foundation**
- Fly.io + Supabase setup, CI/CD pipeline (GitHub Actions → fly deploy)
- Elixir Phoenix project scaffold with module structure
- PostgreSQL schema: School, User, Staff, Child, Classroom, ParentChildLink
- JWT authentication (Guardian): login, refresh, logout
- Row-Level Security setup and test
- Expo React Native project scaffold + WatermelonDB local schema

**Week 3–4: Multi-tenancy + Auth**
- School onboarding flow (API + web UI)
- Invitation flow (director invites teacher, director invites parent)
- Role-based access enforcement (director/teacher/parent plugs)
- User profile management
- Basic Next.js web app with auth

**Week 5–6: Attendance**
- Attendance data model + API
- Attendance marking UI (React Native — fast mobile-first)
- Offline attendance marking (WatermelonDB + sync)
- Safeguarding alert job (Oban scheduled job at configurable time)
- Push notifications for attendance (FCM setup)

**Week 7–9: Daily Reports**
- DailyReport + ActivityLogEntry data model + API
- Daily report entry UI — this is the most UX-intensive feature, allocate time
- Under-3-minutes flow for class-level report with per-child overrides
- Offline report entry and sync
- Report publishing (triggers parent notifications)
- Parent report view (mobile + web)

**Week 10–12: Media**
- Tigris bucket setup, presigned URL generation
- Photo upload flow (React Native camera + offline queue)
- Consent enforcement (DB trigger + application layer)
- Photo tagging UI (teacher tags children, consent-aware)
- Parent photo view with signed URL access
- Video upload (same flow as photo, with duration limit enforcement)
- Background video transcoding job (ffmpeg via Oban)
- GDPR: local photo deletion after sync

**Week 13–14: Messaging**
- Message data model + API
- Phoenix Channels setup for real-time delivery
- Direct messaging UI (teacher ↔ parent)
- Class broadcast UI (teacher → class, one-way)
- School broadcast UI (director → school)
- Message push notifications

**Week 15–16: GDPR + Compliance**
- Consent management UI (parent gives/revokes consent)
- Retention policy enforcement (Oban nightly job)
- Erasure request flow (API + job)
- Audit log views for director
- DSAR data export
- Privacy policy + consent text versioning

**Week 17–18: Polish + Hardening**
- Multilingual support (Spanish full, Catalan strings)
- Error monitoring (Sentry) integration
- Performance testing on mid-range Android
- Security review: rate limiting, header hardening, penetration basics
- App Store submission preparation (iOS + Android)
- Beta testing with 2-3 pilot schools

### 9.2 Complexity Estimates (One Senior Engineer)

| Component | Complexity | Estimate |
|-----------|-----------|----------|
| Foundation + Auth | Medium | 2 weeks |
| Multi-tenancy + Onboarding | Medium | 2 weeks |
| Attendance + Safeguarding | Medium | 2 weeks |
| Daily Reports (including UX) | High | 3 weeks |
| Media (photos + video + consent) | High | 3 weeks |
| Messaging + Real-time | Medium | 2 weeks |
| GDPR compliance features | Medium-High | 2 weeks |
| Polish + hardening + submission | Medium | 2 weeks |
| **Total** | | **~18 weeks** |

This is a realistic timeline for a single senior engineer building a production-quality system with offline support and GDPR compliance built in. Do not compress it — the GDPR components in particular cannot be deferred.

### 9.3 Buy vs Build

| Capability | Decision | Reason |
|-----------|----------|--------|
| Push notifications | Buy (Expo Push / FCM) | Infrastructure commodity |
| Email delivery | Buy (Brevo) | Deliverability is a full-time job |
| SMS alerts | Buy (Vonage) | Carrier relationships required |
| Payment processing | Buy (Stripe) | PCI DSS compliance is non-trivial |
| Authentication | Build (Guardian) | GDPR: no third-party identity dependency |
| Real-time messaging | Build (Phoenix Channels) | No third-party data processor for messages |
| Media storage | Buy (Tigris) | Object storage is a commodity |
| Error monitoring | Buy (Sentry) | Essential, no-brainer |
| Video transcoding | Build V1 (ffmpeg + Oban) | Low volume, no managed EU option that's simple |
| Analytics | Buy (Plausible) | Privacy-first, EU-hosted, no-code setup |
| Search | Build (PostgreSQL FTS) | Not needed until V2 |

---

## 10. Third-Party Services

### Email Delivery: Brevo (formerly Sendinblue)

Brevo is an EU-based (French) email delivery and marketing platform. It is GDPR-compliant by default, has a DPA, and stores data in the EU.

Use case: transactional emails (invitations, password reset, daily report summaries, erasure confirmations).

**Do NOT use:** Mailgun (US), SendGrid (US acquired by Twilio), Postmark (US).

Brevo's free tier handles 300 emails/day — sufficient for development. Paid plans start at €25/month.

### Push Notifications: Firebase Cloud Messaging (FCM) via Expo

FCM is Google infrastructure — it routes globally. Mitigate the GDPR concern by ensuring push payloads contain zero personal data. Configure via Expo Push Notifications SDK for simplified token management.

No EU-native alternative to FCM/APNs exists that has comparable reliability and reach. This is an accepted trade-off documented in your GDPR processing records.

### SMS (Critical Alerts): Vonage (formerly Nexmo)

Vonage is EU-based (UK/EU operations), has a GDPR DPA, and has excellent coverage in Spain. Use for:
- Safeguarding alerts to directors (backup channel when push fails)
- Password reset for parents without email access

Cost: ~€0.05/SMS in Spain. Low volume (emergency use only), negligible cost.

**Alternative:** Twilio works but is US-headquartered. If data residency for phone numbers is a concern, prefer Vonage.

### Video Transcoding: Self-hosted ffmpeg (V1), Mux Europe (V2)

V1: Run ffmpeg on the Fly.io application server via an Oban background job. For 60-second videos at this scale, this is fine. A Fly.io machine with 2 shared vCPUs transcodes a 60-second 1080p video in under 30 seconds.

V2 (if video volume warrants): Evaluate Mux, which has EU data residency options. At V1 scale, do not add the complexity and cost of a managed transcoding service.

### Media CDN: Tigris (built-in)

Tigris has edge caching built into its S3-compatible storage. For a Spain-focused product, Frankfurt origin with Tigris's edge network provides sub-200ms media delivery in Spain. No separate CDN needed in V1.

If you need finer control over cache TTLs or geographic performance at scale, add Cloudflare in front of Tigris — but this is a V2 concern.

### Error Monitoring: Sentry (EU region)

Sentry has an EU data center option (`sentry.io` with EU data residency selected at organization level, or self-hosted). Set the `dsn` to the EU-hosted endpoint.

Configure Sentry to:
- Strip personally identifiable information from error payloads (use `beforeSend` hook to remove user data beyond user ID)
- Not capture request bodies for media endpoints (to avoid capturing photo data)

Cost: Free for < 5,000 errors/month. €26/month for the developer tier.

### Analytics: Plausible Analytics (EU-hosted)

Plausible is an EU-based (Estonia), privacy-first analytics platform that does not use cookies and is GDPR-compliant without a cookie consent banner. It counts page views, sessions, and custom events.

Use for: web app analytics (report views, feature adoption, conversion funnel from invitation to active parent). Do NOT use Google Analytics — it requires a cookie consent banner and transfers data to the US.

Cost: €9/month for small sites.

### Payment Processing: Stripe (SEPA + Cards)

Stripe is the correct choice for a Spanish SaaS company for these reasons:
- SEPA Direct Debit support — schools prefer bank transfer/direct debit over cards for recurring SaaS payments
- Stripe has an EU entity (Stripe Payments Europe, Ireland) for GDPR compliance
- Stripe Billing handles subscription management, invoicing, dunning, and tax (IVA) calculation for Spanish businesses
- Stripe's hosted checkout pages mean you never handle card data (PCI DSS scope reduced to SAQ-A)

Billing model: School pays monthly or annually. Pricing tiers by number of children (e.g., up to 50 children, 51–150, 151+). Stripe Billing handles plan changes, prorations, and SEPA mandates automatically.

### Summary Table

| Category | Service | Monthly Cost (est. V1) | GDPR Compliant |
|----------|---------|----------------------|----------------|
| Hosting | Fly.io (Frankfurt) | ~€40 | Yes |
| Database | Supabase (Frankfurt) | ~€25 | Yes (DPA available) |
| Cache | Upstash Redis (EU) | ~€10 | Yes |
| Media Storage | Tigris | ~€5 | Yes (EU) |
| Email | Brevo | ~€25 | Yes (EU-based) |
| Push | FCM via Expo | Free (at V1 scale) | Conditional (no PII in payloads) |
| SMS | Vonage | ~€5 (emergency only) | Yes (DPA available) |
| Error monitoring | Sentry EU | ~€26 | Yes |
| Analytics | Plausible | ~€9 | Yes |
| Payments | Stripe | % of revenue | Yes (EU entity) |
| CI/CD | GitHub Actions | Free (public) / ~€4 | Yes |
| **Total infrastructure** | | **~€150/month** | |

At €150/month infrastructure cost, you need approximately 3-4 paying schools to cover infrastructure. The unit economics are excellent.

---

## Appendix A: Architectural Decision Records

### ADR-001: Modular Monolith over Microservices

**Status:** Accepted

**Context:** Early-stage product with a solo technical founder. The team will grow to 2-3 engineers within 18 months. The system must be reliable and maintainable. Domain boundaries are hypothesized but not yet validated by production usage.

**Decision:** Build a modular monolith with clear internal module boundaries. Each module (accounts, messaging, daily_reports, media, etc.) owns its data and exposes a public API to other modules. No direct cross-module database access.

**Consequences:**
- Easier: Local development, deployment, debugging, refactoring internal APIs
- Harder: Cannot scale individual modules independently (not needed at this scale)
- Reversible: A well-structured modular monolith can be split into microservices at specific boundaries if independent scaling becomes necessary

### ADR-002: Elixir + Phoenix over Node.js

**Status:** Accepted

**Context:** Real-time messaging (WebSockets), background job processing, high concurrency for push notifications, and long-running processes (offline sync, media processing) are core requirements.

**Decision:** Use Elixir with Phoenix for the backend.

**Consequences:**
- Easier: WebSocket scalability, fault tolerance via OTP, background jobs with Oban
- Harder: Smaller hiring pool than Node.js/Python, founder must be proficient in Elixir
- Not reversible easily: Elixir is a significant investment. The founder must be committed to this choice.

### ADR-003: Shared PostgreSQL Database with RLS for Multi-tenancy

**Status:** Accepted

**Context:** 500 schools at Year 3. Strong tenant isolation required. GDPR requires data separation between schools.

**Decision:** Single PostgreSQL cluster with Row-Level Security enforced by school_id. Every tenant-scoped table has an RLS policy.

**Consequences:**
- Easier: Single migration path, unified monitoring, lower operational overhead
- Harder: A bug in RLS policy could theoretically expose cross-tenant data (defense: policies are simple and testable; also, Supabase's RLS testing tools help)
- Reversible: Can migrate to schema-per-tenant if needed, but this is unlikely to be necessary

### ADR-004: Offline-First Mobile with WatermelonDB

**Status:** Accepted

**Context:** Teachers in rural Spain may have poor or no connectivity during morning routines. Daily report completion must be possible offline.

**Decision:** Use WatermelonDB (SQLite via expo-sqlite) as the local database. Sync via a pull-push protocol using server timestamps as the sync cursor.

**Consequences:**
- Easier: Teachers can always complete their core workflows regardless of connectivity
- Harder: Sync conflicts must be handled explicitly; photos stored locally before sync are a GDPR consideration; more complex application code
- Not easily reversible: Offline-first architecture is a foundational decision that affects every mobile feature

---

*This document is a living reference. Update it as architectural decisions are revisited and as the system evolves from V1 toward V2.*
