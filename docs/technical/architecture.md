# Technical Architecture — Preschool Communication Platform

**Version:** 1.3
**Date:** 2026-04-25
**Status:** Draft for founder review — updated to Next.js-only backend, SSE + Polling replaces Socket.IO
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
  ┌──────────────┐        │  ┌──────────────────────┐  ┌─────────────┐  │
  │  Teacher App  │◄──────┼──►  Next.js 15 App       │  │  BullMQ     │  │
  │  (React Native│  HTTPS│  │  - App Router (UI)    │  │  Worker     │  │
  │   + Expo)     │       │  │  - Route Handlers     │◄─►  - Media    │  │
  └──────────────┘        │  │    (REST API)         │  │  - Notifs   │  │
                          │  │  - SSE /api/stream    │  │  - Retention│  │
  ┌──────────────┐        │  │  - Better Auth        │  │  - Erasure  │  │
  │  Parent App   │◄──────┼──►    /api/auth/*        │  └──────┬──────┘  │
  │  (React Native│  HTTPS│  └──────────┬────────────┘         │         │
  │   + Expo)     │       │             │                       │         │
  └──────────────┘        │  ┌──────────▼────────────┐  ┌──────▼──────┐  │
                          │  │ PostgreSQL (Fly)        │  │   Redis     │  │
  ┌──────────────┐        │  │ Row-level security      │  │ (BullMQ     │  │
  │  Web Browser  │◄──────┼──►  per tenant             │  │  queues,    │  │
  │  (Next.js)    │  HTTPS│  └───────────────────────┘  │  rate limits)│  │
  └──────────────┘        │                              └─────────────┘  │
                          │  ┌───────────────────────────────────────┐   │
                          │  │  Tigris (EU bucket)                    │   │
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
- **At Year 3 scale (500 schools, 60,000 children), a single Node.js node handles this comfortably.** This is not a high-throughput system. It is a data-privacy-sensitive, moderate-concurrency system.
- **TypeScript enforces module boundaries at compile time** — each module has its own clearly scoped API, and cross-module imports are kept explicit and intentional.

The monolith is NOT a compromise. It is the deliberate architecture for this scale and team size.

### 1.3 Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Backend runtime | Next.js 15 App Router (Route Handlers + Server Actions) | Single deployment for both API and UI — no separate Fastify server needed |
| Mobile | Expo WebView shell | Wraps Next.js web app — no separate React Native data layer |
| Frontend web | Next.js 15 App Router | Serves all UI and all API routes in one app |
| Database | PostgreSQL (single cluster) | Row-level security for tenant isolation, JSONB for flexible activity logs |
| Real-time | SSE (`/api/stream`) + polling (`?since=`) | No persistent WebSocket server needed; SSE covers server-push, polling covers everything else |
| Media storage | Tigris (S3-compatible, EU) | S3-compatible API, EU data residency, no egress fees |
| Auth | Better Auth (self-hosted) | Next.js App Router integration, Prisma adapter, JWT cookie cache, email/password + Google/Apple OAuth — all auth data in Fly Postgres Frankfurt |
| Background jobs | BullMQ worker (separate process, same Fly app) | Redis-backed job queue for push notifications, media transcoding, retention, erasure |
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

### 2.1 Backend: Next.js 15 App Router (Route Handlers + Server Actions)

**Next.js serves both the UI and the API. There is no separate backend server.**

This is the correct choice because the mobile app is a WebView shell — all clients (web browsers, Expo WebView, mobile browsers) talk to the same Next.js deployment. Route Handlers replace a dedicated REST API server; Server Actions handle mutations from within Next.js pages. The real-time requirements (see §2.5) are satisfied by SSE and polling, which do not need a persistent WebSocket server.

Specific reasons:

- **One deployment, one codebase.** No separate Fastify server to maintain, deploy, or debug. `fly deploy` ships everything.
- **Route Handlers** (`app/api/v1/...`) handle all REST API calls from the Expo shell and external clients. They are standard `Request`/`Response` — compatible with Web APIs, testable in isolation.
- **TypeScript** throughout: catches tenant-isolation bugs (wrong `school_id`, missing auth checks) at compile time rather than in production. Prisma's generated types give end-to-end type safety from DB schema to API response.
- **BullMQ** for background jobs: push notifications, photo processing, retention deletion, audit flushes. Backed by Redis, with retry logic and dead-letter queues. Runs as a separate Node.js worker process (`worker/index.ts`) deployed alongside the Next.js app on the same Fly.io machine — triggered by jobs enqueued from Route Handlers.
- **Prisma** as ORM: excellent TypeScript integration, clean migration tooling, and the ability to drop to raw SQL for RLS-sensitive queries where needed.

**Project structure:**

```
app/
  api/
    auth/[...all]/     # Better Auth catch-all handler
    v1/
      children/        # Child profile CRUD
      messages/        # Messaging send/receive
      reports/         # Daily reports
      attendance/      # Attendance records
      media/           # Photo/video upload + signed URLs
      consent/         # GDPR consent management
      notifications/   # Push token registration
      gdpr/            # Erasure requests
      schools/         # School settings
      stream/          # SSE endpoint (server-push events)
  (app)/               # Protected app routes (director/teacher/parent UI)
  (auth)/              # Auth screens (better-auth-ui)
lib/
  auth.ts              # Better Auth config
  db.ts                # Prisma client singleton
  storage.ts           # Tigris S3 client
  rls.ts               # RLS session helper
  jobs.ts              # BullMQ queue definitions
  auth-middleware.ts   # requireAuth() helper for Route Handlers
worker/
  index.ts             # BullMQ worker bootstrap (separate process)
  jobs/
    notifications.ts   # Push notification dispatch
    media.ts           # ffmpeg video transcoding
    retention.ts       # Nightly data retention enforcement
    erasure.ts         # GDPR erasure request processor
    safeguarding.ts    # Scheduled safeguarding alert
```

Cross-module calls stay within `lib/` utilities — never importing Prisma models or job definitions from within `app/api/` routes directly. This is the modular boundary enforced by TypeScript path aliases.

### 2.2 Database: PostgreSQL 16

**Use PostgreSQL as the single primary datastore. Add Redis for caching and pub/sub.**

PostgreSQL is the correct choice because:

- **Row-Level Security (RLS)** enforces tenant isolation at the database level, not just application level. Even if application code has a bug, a parent from school A cannot read data from school B.
- **JSONB** columns handle the variable structure of daily activity logs (each school may configure different fields in the future) without sacrificing queryability.
- **Full-text search** in Spanish is built-in with proper dictionary support — you can search message history without Elasticsearch.
- **Audit triggers** can capture all mutations to sensitive tables directly in Postgres before they reach the application layer.
- **Prisma** has first-class PostgreSQL support. For RLS-sensitive queries, use `prisma.$executeRaw` to set the session variable before queries.

Redis (via Upstash EU Frankfurt) for:
- Rate limiting counters (sliding window per user/IP)
- BullMQ job queues (push notifications, media processing, retention, erasure)

Do NOT use Redis for anything that must survive a restart. BullMQ jobs use Redis but are designed for at-least-once delivery with retry — for truly durable, ACID-guaranteed operations use PostgreSQL transactions.

### 2.3 Mobile: Expo WebView Shell

**Use Expo as a thin native shell wrapping the Next.js web app in a WebView.**

The mobile app is not a separate React Native application with its own data layer. It is an Expo project that renders the Next.js web app via `react-native-webview`, plus a native bridge for push notifications and OAuth deep links.

This is the correct choice for MVP because:

- **Zero UI duplication.** One codebase (Next.js) serves both the web portal and mobile. Changes deploy to both simultaneously.
- **better-auth-ui works as-is.** The shadcn/ui auth components render correctly in a WebView — no mobile-specific auth screens to build.
- **Dramatically reduced scope.** No WatermelonDB, no offline sync protocol, no native camera integration. Mobile complexity is eliminated for MVP.
- **Expo EAS Build** handles iOS/Android builds in CI. OTA updates via EAS Update push web app changes without an App Store review cycle.

**What the Expo shell provides:**
- `react-native-webview` rendering the Next.js web app
- `expo-notifications` for FCM/APNs push notification registration — the device token is sent to the server on app open; notification payloads contain zero personal data; actual content is fetched from the EU API when the user taps
- `expo-linking` for deep link handling — required for Google and Apple OAuth callbacks to return to the app rather than orphaning in a browser tab
- A custom scheme (e.g. `guarda://`) registered as a redirect URI in Google and Apple's OAuth console

**What it does NOT include:**
- WatermelonDB or any local SQLite database
- Offline data sync
- Native camera or file system integration (handled via browser `<input type="file">` in WebView)
- Any application business logic

**Cookie session handling:** Better Auth's JWT cookie sessions work natively in WebView. The WebView maintains its own cookie jar — the HttpOnly JWT cookie is sent on every request automatically. No custom token handling required on the mobile side.

**OAuth flow in WebView:** When a user taps "Sign in with Google", the WebView loads the Google consent screen. After consent, Google redirects to your callback URL. Better Auth completes the OAuth exchange server-side and sets the session cookie. The WebView then navigates to the app's home screen — the flow is identical to web.

### 2.4 Web Frontend + API: Next.js 15 (App Router)

**Next.js is both the web application and the API server. Everything runs in one deployment.**

Because the React Native app is a WebView wrapper (§2.3), Next.js serves all users — desktop browsers, mobile browsers, and the Expo WebView shell. There is no separate mobile UI codebase and no separate API server.

The web app serves three distinct user groups:
1. **Directors** — school administration, staff and parent invitations, school settings, billing
2. **Teachers** — daily report entry, attendance, messaging, photo upload
3. **Parents** — viewing their children's reports, photos, messages, consent management

Next.js reasons:
- **better-auth-ui** (shadcn/ui) provides drop-in auth screens (sign in, sign up, forgot password) that match the app's design system. Zero custom auth UI to build.
- Server-side rendering improves perceived performance for parents loading photo galleries, especially on mid-range Android devices via the WebView.
- Route Handlers in the App Router handle all REST API calls — same process, no inter-service latency.
- One `fly deploy` ships UI, API, and auth in a single step.

### 2.5 Real-Time: SSE + Polling

**Use Server-Sent Events for server-push and HTTP polling for periodic refreshes. No WebSocket server.**

This product's real-time traffic pattern is low-frequency and mostly one-directional: a teacher posts a photo or publishes a report, and parents should see it within seconds while they have the app open. This does not require a persistent bidirectional connection.

**SSE (`GET /api/v1/stream`)**

Server-Sent Events are a streaming HTTP response (`Content-Type: text/event-stream`) supported natively in browsers and in Next.js Route Handlers via the Web Streams API. The client opens one long-lived connection; the server pushes events when something relevant happens.

```typescript
// app/api/v1/stream/route.ts
export async function GET(request: Request) {
  const { schoolId } = await requireAuth(request)
  const encoder = new TextEncoder()

  const stream = new ReadableStream({
    start(controller) {
      const send = (event: string, data: unknown) =>
        controller.enqueue(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`))

      // Poll for new events every 5 seconds, push only what's new
      const interval = setInterval(async () => {
        const events = await getRecentEvents(schoolId, lastSeen)
        events.forEach(e => send(e.type, e.payload))
      }, 5000)

      request.signal.addEventListener('abort', () => clearInterval(interval))
    },
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  })
}
```

SSE events pushed to clients:
- `message.new` — a direct message or broadcast arrived for this user
- `report.published` — a daily report was published for a classroom this parent has a child in
- `media.ready` — a photo/video finished processing and is available to view

**Polling (`GET /api/v1/{resource}?since={isoTimestamp}`)**

For non-urgent content (attendance history, report list, photo gallery), the client fetches on a timer. Every feed endpoint accepts a `since` query parameter and returns only items newer than that timestamp. The client stores the timestamp of the last successful response and uses it on the next poll.

```
GET /api/v1/messages?since=2026-04-25T10:00:00Z
→ returns messages received after that time, for this user's school + role
```

Polling intervals by resource type:
- Active message thread: 15 seconds (while the user has it open)
- General notifications badge: 30 seconds
- Photo gallery / report list: on-focus (when user navigates to the view)

**Push notifications handle the alert layer**

Push notifications (FCM/APNs via Expo) fire when the app is closed or backgrounded. The app does not need to be open for parents to be alerted. SSE and polling only matter while the user has the app in the foreground — their job is to refresh content already on screen without requiring a manual pull-to-refresh.

**Delivery flow for a new message:**

```
1. Teacher sends message → POST /api/v1/messages
2. Route Handler persists to PostgreSQL
3. Route Handler enqueues BullMQ job: { type: 'push_notification', ... }
4. BullMQ worker dispatches FCM push to all offline recipients
5. Any recipient currently connected via SSE receives message.new event within 5s
6. Any recipient not connected via SSE sees the message next time they open the thread (polling)
```

No Redis pub/sub is needed for event distribution — the SSE endpoint polls PostgreSQL directly. At V1 scale (500 schools, low concurrent users per school) a 5-second DB poll is trivially cheap.

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

For video: store the original upload. Use a background BullMQ job to transcode to H.264/AAC MP4 using `ffmpeg` running on the server for V1. At Year 3 scale, evaluate moving to a managed transcoding service. Do NOT use Mux in V1 — it is US-based and overkill for 60-second videos at this scale.

### 2.8 Auth: Better Auth

**Use Better Auth with the Prisma adapter. Do not build a custom auth system, and do not use Supabase Auth.**

Better Auth is a self-hosted, framework-agnostic TypeScript authentication library. It integrates with Next.js App Router via a catch-all Route Handler, uses the same Fly Postgres database via Prisma, and sends no auth data to third-party infrastructure. All auth data stays in Frankfurt.

**What Better Auth handles:**
- Email/password login with secure password hashing
- Social login — Google and Apple OAuth (relevant for Spanish parents and teachers)
- Password reset via email (magic link, sent through Brevo)
- Session management with configurable expiry and automatic refresh
- JWT cookie cache — sessions issued as signed stateless JWTs in HttpOnly cookies, eliminating a database lookup on every request

**What we build on top:**
- Custom invitation flow (§6.3) — director invites staff and parents by email; a signed token is generated, sent via Brevo, validated on click, and the appropriate `app_users` / `staff` / `parent_child_links` record is created
- Role injection — `app_users.role` is fetched once per request in the `requireAuth()` helper and returned to the Route Handler

**Better Auth tables (managed by the library — do not modify directly):**

| Table | Purpose |
|-------|---------|
| `user` | Auth identity: id, name, email, emailVerified, image, createdAt, updatedAt |
| `session` | Session records (backing store even in JWT cache mode) |
| `account` | OAuth provider credentials (Google, Apple tokens) |
| `verification` | Magic link and email verification tokens |

Your domain tables (`app_users`, `staff`, `schools`, etc.) reference `user.id` as a foreign key. See §3.1.

**Next.js App Router integration:**

Better Auth mounts at `app/api/auth/[...all]/route.ts` as a catch-all Route Handler:

```typescript
// lib/auth.ts
export const auth = betterAuth({
  database: prismaAdapter(prisma, { provider: 'postgresql' }),
  session: {
    cookieCache: {
      enabled: true,
      maxAge: 60 * 60, // 1-hour stateless JWT, auto-refreshed
    },
  },
  emailAndPassword: { enabled: true },
  socialProviders: {
    google: { clientId: env.GOOGLE_CLIENT_ID, clientSecret: env.GOOGLE_CLIENT_SECRET },
    apple:  { clientId: env.APPLE_CLIENT_ID,  clientSecret: env.APPLE_CLIENT_SECRET },
  },
  trustedOrigins: [env.WEB_ORIGIN],
})

// app/api/auth/[...all]/route.ts
import { auth } from '@/lib/auth'
export const { GET, POST } = auth.handler
```

**`requireAuth` helper (used in every protected Route Handler):**

```typescript
// lib/auth-middleware.ts
export async function requireAuth(request: Request) {
  const session = await auth.api.getSession({ headers: request.headers })
  if (!session) throw new Response('Unauthorized', { status: 401 })

  const appUser = await prisma.appUser.findUnique({ where: { authUserId: session.user.id } })
  if (!appUser) throw new Response('No profile', { status: 403 })

  // Set RLS session variable for all DB queries in this request scope
  await prisma.$executeRaw`SELECT set_config('app.school_id', ${appUser.schoolId}, true)`

  return { id: appUser.id, schoolId: appUser.schoolId, role: appUser.role }
}
```

**Token storage:**
- **Web:** JWT in HttpOnly + Secure + SameSite=Strict cookie — inaccessible to JavaScript, XSS-safe
- **Mobile (WebView):** Same cookie, managed automatically by the WebView's cookie jar — no custom handling required

**Role model:**
- `DIRECTOR` — full access to their school's data
- `TEACHER` — access to assigned classrooms only
- `PARENT` — access to their own children's data only (enforced by RLS + application layer)

Role-based access is enforced in Route Handler middleware (`requireAuth()`), not in the frontend.

**Do NOT use:** Auth0 (routes identity through US infrastructure by default), Clerk (no EU region), Supabase Auth (eliminated — auth data must not be split from application data across separate hosting).

### 2.9 Hosting / Infrastructure: Fly.io (Frankfurt Region)

**Deploy everything on Fly.io in the `fra` (Frankfurt) region for EU data residency.**

Fly.io advantages for this use case:
- Excellent Node.js support — Docker-based deployment, `fly deploy` from CI, no Kubernetes needed.
- Managed PostgreSQL (Fly Postgres) in Frankfurt — same private network as the app, no public internet exposure.
- Simple deployment model — `fly deploy` from CI. No Kubernetes, no ECS task definitions.
- Private networking between services (no public internet between app and database).
- SSE connections are stateless relative to the server — horizontal scaling works without a shared message bus.
- Reasonable cost at this scale — a 2-node app cluster + managed Postgres + Redis starts under €100/month.

Use **Fly Postgres (Frankfurt region)** for PostgreSQL.

Fly Postgres runs inside the same Fly.io private network as the application — the database is never exposed to the public internet. Advantages:
- Private networking between app and database via Fly.io's WireGuard mesh — no connection string exposed, no egress fees
- Frankfurt region for EU data residency
- Point-in-time recovery and automated daily backups included
- PgBouncer connection pooling sidecar available via `fly.toml`
- Billed as part of the Fly.io account — no separate database service to manage or sign a DPA with
- Prisma migrations are the schema management tool — no need for a database web UI

**Infrastructure as Code:** Use Fly.io's `fly.toml` for app configuration and keep it in the repository. Do NOT use Terraform in V1 — the infrastructure is simple enough that `fly.toml` + Prisma migrations is sufficient.

### 2.10 CI/CD: GitHub Actions

**Use GitHub Actions for CI/CD.**

Pipeline stages:
1. `test` — run Jest tests + ESLint + TypeScript type check (`tsc --noEmit`)
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

User (Better Auth identity — auth.user table)
  ├── has one AppUser (your domain profile: school_id, role)
  └── AppUser polymorphic: belongs to Staff OR Parent

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

**Critical constraint:** A `media_child_tags` row cannot be inserted unless a valid `consent_records` row exists for the child with `consent_type = 'photo_sharing'` and `status = 'granted'`. This is enforced via a PostgreSQL trigger and in the Node.js application layer (defense in depth).

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
| Application database | Fly Postgres (PostgreSQL) | Frankfurt, Germany |
| Auth data | Better Auth (self-hosted, same DB) | Frankfurt, Germany |
| Redis cache | Upstash | EU (Frankfurt) |
| Media storage | Tigris | EU (Frankfurt) |
| Application servers | Fly.io | Frankfurt, Germany |
| Email delivery | Brevo (EU-based) | EU |
| Push notification routing | Expo Push (proxied via own server) | See note below |

**Push notification note:** FCM infrastructure routes through Google's global network. The push notification payload must never contain personal data or message content — only a notification ID. The receiving device calls your EU-hosted API to fetch the actual content. This architecture means personal data never leaves the EU.

**Data Processing Agreements (DPAs) required with:**
- Fly.io — available on request (covers both app servers and Fly Postgres)
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

Layer 1 — Application logic: Before creating a `media_child_tags` record, the `consent` module checks for a valid `consent_records` row.

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

Implementation via BullMQ scheduled job (runs nightly at 02:00 EU time):

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

Implementation: Erasure requests create an `ErasureRequest` record with status `pending`. A BullMQ job processes them asynchronously within 30 days (GDPR requirement) and sends a completion notification. All erasure completions are logged in the audit trail.

### 4.6 Encryption

**In transit:** TLS 1.3 mandatory for all connections. HSTS enforced. Fly.io handles TLS termination at the edge.

**At rest:**
- Database: Fly Postgres encrypts the storage volume at rest (AES-256). This is infrastructure-level encryption.
- Media: Tigris encrypts all objects at rest (AES-256).
- Field-level encryption: Encrypt sensitive fields in the application layer before they reach the database (use `@noble/ciphers` or Node.js native `crypto` AES-256-GCM). Fields requiring field-level encryption:
  - `children.medical_notes`
  - `children.dietary_notes`
  - `users.phone_number`
  - `consent_records.ip_address`

Field-level encryption means even a database dump does not expose these values without the application's encryption key.

**Encryption key management:** Store encryption keys in environment variables (Fly.io secrets), not in the database. Rotate keys annually — implement a key version field alongside encrypted values to support gradual re-encryption during rotation.

### 4.7 DPO Support

A Data Protection Officer (if the school is large enough to require one, or if you appoint one voluntarily) needs the following capabilities, all of which the system must support:

- **Data subject access request (DSAR) export:** The system can generate a structured JSON export of all personal data for a given parent or child, including audit trail of who accessed their data.
- **Consent dashboard:** A read-only view showing all consents granted/revoked per child per school.
- **Retention policy audit:** A report showing when data is scheduled for deletion and what has been deleted.
- **Processing activity record (Article 30 record):** The system generates a machine-readable list of all data categories processed, their legal basis, and retention periods — suitable for inclusion in the school's ROPA.
- **Breach notification support:** Audit logs provide the data needed to determine the scope of a breach and notify the AEPD (Spanish data protection authority) within 72 hours.

---

## 5. Offline Architecture

**Offline support is deferred post-MVP.**

The React Native app is an Expo WebView shell — it renders the Next.js web app and has no local data layer. All features require an active internet connection for MVP.

This is an explicit product decision, not an oversight. The target user (teachers in Spanish guarderías) is on WiFi or mobile data during working hours. Offline support adds significant engineering complexity (sync protocol, conflict resolution, local schema, GDPR implications for locally-stored child data) that is not justified before product-market fit is established.

**Post-MVP offline path (if validated as a real need):**
- Web app: Service Worker + Cache API for read-only offline access to the last-loaded state
- Native app: Upgrade from WebView wrapper to a full React Native implementation with WatermelonDB for offline daily reports and attendance marking

No offline architecture decisions are locked in at this stage.

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
-- Set at the start of every DB transaction from Node.js
SELECT set_config('app.school_id', '<uuid>', true);

-- Policy on every tenant-scoped table:
CREATE POLICY tenant_isolation ON children
  USING (school_id = current_setting('app.school_id')::UUID);
```

The `requireAuth()` helper (§2.8) sets `app.school_id` from the authenticated session before any database query. The RLS policy ensures no query can return rows from a different school.

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
  2. Create Better Auth user record for the director
  3. Create AppUser record (auth_user_id → Better Auth user.id, school_id, role: director)
  4. Create Staff record linked to AppUser
  5. Send welcome email via Brevo with a Better Auth magic link (first login)
  6. Create default RetentionPolicy (365 days)
  7. Create default school Settings
  8. Log audit event: school.created
  9. Create Stripe Customer (async BullMQ job, non-blocking)
```

Steps 1–8 run inside a single Prisma `$transaction` — all succeed or all roll back. School setup is complete in under 1 second.

**Invitation flow (staff and parents):**
1. Director submits an invitation form (email, role, optionally classroom or child)
2. Server generates a signed invitation token (UUID stored in an `invitations` table with expiry, role, school_id, and optionally child_id)
3. Brevo sends the invitation email with a link containing the token
4. Invitee clicks the link → server validates token → Better Auth account created (or existing account linked) → `AppUser` + `Staff` or `ParentChildLink` record created → token consumed
5. Invitee is redirected to the app, already authenticated

After onboarding, the director uses the web app to:
- Create classrooms
- Invite teachers and parents via the invitation flow above
- Import or manually add children
- Configure safeguarding alert time

Child import: support CSV import (first name, last name, date of birth, classroom). The director uploads a CSV; a background job validates and creates Child records. Parent invitation emails are sent after child creation.

---

## 7. Security Considerations

### 7.1 Authentication

Better Auth issues sessions as **stateless JWTs stored in HttpOnly cookies** (JWT cookie cache mode). The JWT is signed with a secret key configured as a Fly.io secret — never stored in the database or exposed to the client.

Token storage:
- **Web:** JWT in HttpOnly + Secure + SameSite=Strict cookie. Inaccessible to JavaScript — XSS attacks cannot read or steal it.
- **Mobile (WebView):** Same cookie, managed automatically by the WebView's cookie jar. No Expo SecureStore or AsyncStorage involved.

Session management:
- Better Auth's `session` table records all active sessions with `userId`, `token`, `expiresAt`, `ipAddress`, `userAgent`.
- The JWT cookie cache has a 1-hour validity window — after expiry, Better Auth re-queries the session table and issues a fresh JWT transparently.
- Sessions expire after 7 days by default (configurable). Logging out invalidates the session record server-side and clears the cookie.
- A director can see all active sessions for their account and revoke any of them via the Better Auth session management API.
- After 3 failed login attempts from the same IP, impose a 5-minute lockout. After 10, require CAPTCHA. (Implemented in the Route Handler rate-limit layer, not in Better Auth.)

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

Authorization is enforced in Route Handler middleware, not in the frontend. Every API endpoint calls `requireAuth()` and checks the authenticated user's role and relationship to the requested resource before performing any database operation.

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

- **Rate limiting:** 100 requests/minute per authenticated user, 10 requests/minute for unauthenticated login attempts. Enforced via Redis counter with sliding window in Route Handler middleware.
- **Input validation:** All inputs validated with Zod schemas at the Route Handler level before reaching business logic. Binary content type validation for media uploads.
- **SQL injection:** Impossible via Prisma parameterized queries. Never use string interpolation in raw SQL (`$executeRaw` uses tagged template literals that are parameterized automatically).
- **CORS:** Strict origin allowlist via Next.js `next.config.ts` headers — only the known web frontend origin is permitted for API routes.
- **Content Security Policy:** Strict CSP headers via `next.config.ts`. Media served from Tigris, not from the same origin.
- **Security headers:** X-Frame-Options: DENY, X-Content-Type-Options: nosniff, Referrer-Policy: no-referrer — set via Next.js response headers config.

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
- Single Fly Postgres instance (vertical scaling handles this scale comfortably)
- Single Next.js deployment (SSE connections are lightweight HTTP streams — no WebSocket state to synchronize between nodes)
- Tigris media storage (object storage is inherently scalable)
- Current data model and RLS approach

**What to monitor and potentially address at ~300 schools:**

1. **Database connection pooling:** Configure PgBouncer as a sidecar on Fly Postgres. If you add more Node.js nodes, the pool size may need tuning. This is a configuration change, not an architecture change.

2. **Audit log table growth:** The `audit_events` table grows linearly with usage. The monthly partition strategy means you can archive/drop old partitions without locking the table. Start archiving partitions older than 5 years to cold storage (S3 Glacier equivalent in EU).

3. **Media storage costs:** 500 schools × ~20 photos/day × 365 days × 3MB/photo = ~11TB/year. Tigris costs approximately €0.015/GB/month — about €165/month at this volume. Not a concern.

4. **Push notification throughput:** At 500 schools, a simultaneous daily report publish by all teachers at ~09:00 generates ~30,000 push notifications in a few minutes. BullMQ with 10-20 concurrent workers handles this. If needed, add a dedicated BullMQ queue for notifications with higher concurrency.

### 8.2 What to Defer to Phase 2

| Item | Why Defer |
|------|-----------|
| Read replicas | Not needed until query performance degrades. Fly Postgres read replicas are a `fly postgres create --replica` command when needed. |
| CDN for media | Tigris has edge caching built in. Only need a dedicated CDN if serving globally, which is not the plan. |
| Separate notification service | BullMQ handles V1 scale. Extract if notification volume warrants dedicated workers. |
| Full-text search service | PostgreSQL FTS handles Spanish text search adequately through Year 3. Elastic/Typesense deferred. |
| Event sourcing / CQRS | Premature for this domain. Add if reporting requirements become complex. |
| Separate read model for analytics | Deferred until you have a dashboard product to build. |

### 8.3 Database Scaling Path

```
V1 (now – Year 1):
  Fly Postgres, single instance, Frankfurt
  Connection pooling via PgBouncer sidecar

V2 (Year 2–3):
  Add read replica for reporting queries
  Archive audit_events partitions > 2 years to cold storage

V3 (if needed, Year 4+):
  Evaluate vertical scaling (larger Fly machine) before horizontal
  If horizontal: Citus for partitioning by school_id (transparent to application)
  At this point: re-evaluate if some schools are large enough to warrant dedicated schemas
```

The correct order is always: optimize queries first, add indexes second, scale vertically third, scale horizontally last. You are years away from needing horizontal database scaling.

---

## 9. Development Roadmap (Technical)

### 9.1 Critical Path to Shippable V1

The order matters. Build in this sequence to unblock everything else:

**Week 1–2: Foundation**
- Fly.io + Fly Postgres setup, CI/CD pipeline (GitHub Actions → fly deploy)
- Next.js 15 + TypeScript project scaffold with App Router and Route Handlers
- PostgreSQL schema + Prisma setup: School, AppUser, Staff, Child, Classroom, ParentChildLink
- Better Auth setup: Prisma adapter, JWT cookie cache, email/password, Google + Apple OAuth — mounted at `app/api/auth/[...all]/route.ts`
- Row-Level Security setup and test (`requireAuth()` sets `SET LOCAL app.school_id`)
- better-auth-ui auth screens (sign in, sign up, forgot password)
- BullMQ worker scaffold (`worker/index.ts`) deployed as a separate process on the same Fly machine
- Expo WebView shell: react-native-webview + expo-notifications + expo-linking

**Week 3–4: Multi-tenancy + Auth**
- School onboarding flow (API + web UI)
- Invitation flow (director invites teacher, director invites parent)
- Role-based access enforcement (director/teacher/parent via `requireAuth()` in Route Handlers)
- User profile management
- Basic Next.js web app with auth

**Week 5–6: Attendance**
- Attendance data model + API
- Attendance marking UI (React Native — fast mobile-first)
- Attendance marking UI (online only for MVP)
- Safeguarding alert job (BullMQ scheduled job at configurable time)
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
- Background video transcoding job (ffmpeg via BullMQ)
- GDPR: local photo deletion after sync

**Week 13–14: Messaging**
- Message data model + API (Route Handlers)
- SSE endpoint (`/api/v1/stream`) — server pushes `message.new` events to connected clients
- Polling fallback for thread view (`?since=` parameter on messages endpoint)
- Direct messaging UI (teacher ↔ parent)
- Class broadcast UI (teacher → class, one-way)
- School broadcast UI (director → school)
- Message push notifications (BullMQ job for offline recipients)

**Week 15–16: GDPR + Compliance**
- Consent management UI (parent gives/revokes consent)
- Retention policy enforcement (BullMQ nightly job)
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
| Authentication | Better Auth (self-hosted) | Runs in-process, Prisma adapter, all data in Fly Postgres Frankfurt — no third-party auth host |
| Real-time messaging | Build (SSE + polling, native to Next.js) | No third-party dependency; SSE is a native HTTP feature, no persistent WebSocket server |
| Media storage | Buy (Tigris) | Object storage is a commodity |
| Error monitoring | Buy (Sentry) | Essential, no-brainer |
| Video transcoding | Build V1 (ffmpeg + BullMQ) | Low volume, no managed EU option that's simple |
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

V1: Run ffmpeg on the Fly.io application server via a BullMQ background job. For 60-second videos at this scale, this is fine. A Fly.io machine with 2 shared vCPUs transcodes a 60-second 1080p video in under 30 seconds.

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
| Hosting + DB | Fly.io Frankfurt (app + Fly Postgres) | ~€55 | Yes (DPA available) |
| Auth | Better Auth (self-hosted, no extra cost) | €0 | Yes (data stays in Fly Postgres) |
| Cache | Upstash Redis (EU) | ~€10 | Yes |
| Media Storage | Tigris | ~€5 | Yes (EU, Fly.io subsidiary) |
| Email | Brevo | ~€25 | Yes (EU-based) |
| Push | FCM via Expo | Free (at V1 scale) | Conditional (no PII in payloads) |
| SMS | Vonage | ~€5 (emergency only) | Yes (DPA available) |
| Error monitoring | Sentry EU | ~€26 | Yes |
| Analytics | Plausible | ~€9 | Yes |
| Payments | Stripe | % of revenue | Yes (EU entity) |
| CI/CD | GitHub Actions | Free (public) / ~€4 | Yes |
| **Total infrastructure** | | **~€135/month** | |

At ~€135/month infrastructure cost, you need 3 paying schools to cover infrastructure. The unit economics are excellent.

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

### ADR-002: Better Auth over Supabase Auth

**Status:** Accepted (2026-04-24)

**Context:** The original architecture used Supabase Auth (EU Frankfurt) for authentication. Auth data was stored in Supabase's `auth.users` table, separate from application data in Fly Postgres. The React Native app was a native WatermelonDB-based client requiring Supabase JS SDK integration.

**Decision:** Replace Supabase Auth with Better Auth (self-hosted, Prisma adapter, Fly Postgres). Replace the native React Native client with an Expo WebView shell.

**Consequences:**
- Easier: All data (auth + application) in one Fly Postgres instance — one DPA, one host, simpler ops. No Supabase JS SDK. Auth screens provided by better-auth-ui (shadcn/ui) for the Next.js web app, reused automatically in the WebView mobile shell.
- Harder: Custom invitation flow must be implemented (Better Auth has no built-in invite-by-email). Upgrading from WebView to native client later requires rebuilding mobile UI.
- Accepted trade-off: Invitation flow is ~50 lines of code. WebView is sufficient for MVP; native client upgrade is a concrete future path if offline or performance requirements arise.

### ADR-003: Shared PostgreSQL Database with RLS for Multi-tenancy

**Status:** Accepted

**Context:** 500 schools at Year 3. Strong tenant isolation required. GDPR requires data separation between schools.

**Decision:** Single PostgreSQL cluster with Row-Level Security enforced by school_id. Every tenant-scoped table has an RLS policy.

**Consequences:**
- Easier: Single migration path, unified monitoring, lower operational overhead
- Harder: A bug in RLS policy could theoretically expose cross-tenant data (defense: policies are simple and testable; write integration tests that assert cross-tenant queries return empty results)
- Reversible: Can migrate to schema-per-tenant if needed, but this is unlikely to be necessary

### ADR-004: Expo WebView Shell over Native React Native Client

**Status:** Accepted (2026-04-24, supersedes previous offline-first mobile decision)

**Context:** The original mobile architecture planned a full React Native client with WatermelonDB for offline-first data, Expo SecureStore for token management, and native camera/file system integration. This significantly increased scope for MVP.

**Decision:** Replace the native React Native client with an Expo WebView shell that renders the Next.js web app. Native bridge covers push notifications and OAuth deep links only. Offline support deferred post-MVP.

**Consequences:**
- Easier: No WatermelonDB, no sync protocol, no native camera integration. Mobile is ~2 days of work instead of 4 weeks. better-auth-ui auth screens work in WebView with no changes. One UI codebase for web and mobile.
- Harder: No offline capability for MVP. Upgrading to native client later requires rebuilding mobile UI. WebView performance ceiling lower than native (acceptable for this use case).
- Accepted trade-off: Offline is not validated as a requirement yet. Teachers in target schools are on WiFi. Native upgrade is a concrete future path gated on user research confirming offline need.

---

### ADR-005: Next.js-Only Backend, SSE + Polling over Fastify + Socket.IO

**Status:** Accepted (2026-04-25, supersedes Fastify API server and Socket.IO real-time layer)

**Context:** The original architecture used a separate Fastify server for the REST API and WebSocket layer (Socket.IO with Redis adapter), deployed alongside the Next.js web app. The mobile app is an Expo WebView shell with no native data layer. The real-time requirements are low-frequency server-to-client pushes: teacher posts a photo, parent sees it; daily report published, parent is notified.

**Decision:** Eliminate the Fastify server entirely. Next.js App Router handles all HTTP via Route Handlers. Replace Socket.IO with SSE (`/api/v1/stream`) for server-push events and polling (`?since=` query parameter) for periodic refreshes. BullMQ workers remain as a separate process for background jobs.

**Consequences:**
- Easier: One deployment (`fly deploy`), one codebase, no cross-service latency, no Socket.IO Redis adapter to configure. SSE is a native browser/Web API feature — no library, no extra dependency.
- Harder: SSE is one-directional (server → client only). If a future feature requires client-to-server real-time events (e.g. collaborative editing, live typing indicators), SSE would need to be supplemented. This is not a requirement for this product.
- Accepted trade-off: Push notifications (FCM/APNs) already handle the "alert while app is closed" case. SSE handles the "refresh content while app is open" case. Together they cover the full notification surface without a persistent WebSocket connection.

---

*This document is a living reference. Update it as architectural decisions are revisited and as the system evolves from V1 toward V2.*
