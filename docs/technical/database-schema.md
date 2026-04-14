# Database Schema — Prisma
**Product Area**: Technical
**Last Updated**: 2026-04-14
**Version**: 1.3
**Status**: Draft — V1 scope

---

## Design Decisions

| Decision | Choice | Reason |
|---|---|---|
| ORM | Prisma | TypeScript-first, clean migration tooling, Supabase compatible |
| Auth | Supabase Auth | Handles email/password, social login (Google, Apple), password reset, invite flows — no custom auth code |
| Identity model | `users` (identity) + `school_memberships` (role per school) | A user has one login but can belong to multiple schools with different roles. Solves the multi-school director case |
| Tenant isolation | `school_id` on every table + PostgreSQL RLS | JWT carries the active `school_id` (from the selected membership); RLS blocks cross-tenant reads at DB level |
| UUIDs | `gen_random_uuid()` (PostgreSQL 16 built-in) | No pgcrypto extension needed, no sequential ID leakage |
| Classroom assignment | Simple FK on `children.classroom_id` | No history table in V1; add `classroom_enrollments` if mid-year moves become a requirement |
| Guardian limit | No maximum — `parent_child_links` is an open join table | Handles separated parents, shared custody, multiple guardians |
| Soft deletes | Only on `schools` and `media` | Schools: data must survive cancellation for GDPR export requests. Media: soft delete before storage deletion. Everything else: hard delete or `active` flag |
| Audit partitioning | Note-only in V1 | `audit_events` should be range-partitioned by `occurred_at` month via a raw SQL migration. Prisma does not support declarative partitioning — add this in the initial migration file manually |
| Denorm schoolId | schoolId on every table (including join tables) | RLS policies do a direct column check: `school_id = (auth.jwt() ->> 'school_id')::uuid`. A subquery join inside an RLS policy fires on every row read — at 100 messages × 30 parents that's 3,000 inline joins. Denorming schoolId trades ~4 bytes per row for zero-join RLS. |
| Stripe customer ID | `stripeCustomerId` lives on `School`, not `Subscription` | One Stripe customer per school across all lifecycle events. Putting it on `Subscription` would create a 3NF violation (it depends on school, not on the subscription row). The webhook receiver does a single `WHERE stripe_customer_id = ?` on `schools`. |
| SchoolMembership active flag | Enforced by partial unique index | `isActive` flag needs a DB-level guard: `UNIQUE (user_id) WHERE is_active = true`. Without it two concurrent school-switch requests can both succeed and leave two active memberships, causing the JWT hook to pick arbitrarily. Add in raw migration. |
| ConsentRecord consistency | CHECK constraint required | `status = REVOKED` and `revoked_at IS NOT NULL` must always be in sync. A plain boolean-vs-timestamp pair is a consistency hazard for GDPR audits. Add a raw SQL CHECK constraint. |
| AttendanceRecord classroomId | Intentional snapshot | Stores the child's classroom at the time of the record, not a live FK. If a child moves classrooms, historical attendance shows the original classroom. Do not remove or derive at query time. |

---

## Entity Map

```
School (tenant root)
  ├── SchoolMembership (User ↔ School join — role lives here, not on User)
  ├── Subscription (Stripe billing history — one row per lifecycle event)
  ├── User (identity only)                        ← references auth.users via auth_id
  │     ├── DevicePushToken
  │     └── NotificationPreference
  ├── Classroom
  │     └── ClassroomStaff (User ↔ Classroom join)
  ├── Child
  │     ├── ParentChildLink (User ↔ Child join)
  │     ├── ConsentRecord
  │     ├── AttendanceRecord
  │     ├── ActivityLogEntry
  │     └── MediaChildTag
  ├── DailyReport (belongs to Classroom)
  │     ├── ActivityLogEntry (per-child overrides)
  │     └── Media
  ├── Media
  │     └── MediaChildTag (child tagging with consent snapshot)
  ├── Message
  │     └── MessageReceipt
  └── AuditEvent
```

---

## Prisma Schema

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─── Enums ────────────────────────────────────────────────────────────────────

enum UserRole {
  DIRECTOR
  TEACHER
  PARENT
}

enum SubscriptionStatus {
  TRIAL
  ACTIVE
  SUSPENDED
  CANCELLED
}

enum ConsentType {
  DATA_PROCESSING   // required — legal basis: contract
  PHOTO_SHARING     // optional
  VIDEO_SHARING     // optional
  RESEARCH          // optional — anonymous analytics
}

enum ConsentStatus {
  GRANTED
  REVOKED
}

enum MessageType {
  DIRECT             // staff → one parent, or parent → staff
  CLASS_BROADCAST    // staff → all parents in a classroom (no reply-all)
  SCHOOL_BROADCAST   // director → all parents in school
}

enum MediaType {
  PHOTO
  VIDEO
}

enum MediaProcessingStatus {
  PENDING  // upload received, not yet processed
  READY    // thumbnail generated, available to serve
  FAILED   // processing error
}

enum AttendanceStatus {
  PRESENT
  ABSENT
  LATE
}

enum AbsenceReason {
  SICK
  FAMILY
  UNKNOWN
  OTHER
}

enum PushPlatform {
  IOS
  ANDROID
  WEB
}

enum NotificationType {
  NEW_MESSAGE
  DAILY_REPORT
  NEW_PHOTO
  ATTENDANCE_ALERT
  SAFEGUARDING_ALERT
}

enum MealStatus {
  GOOD
  PARTIAL
  POOR
}

enum MoodStatus {
  HAPPY
  CALM
  TIRED
  DIFFICULT
}

enum ActorType {
  STAFF
  PARENT
  SYSTEM
}

// ─── School (Tenant Root) ─────────────────────────────────────────────────────

model School {
  id                    String             @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name                  String
  slug                  String             @unique            // URL identifier, e.g. "guarderia-pulgarcito"
  locale                String             @default("es")
  timezone              String             @default("Europe/Madrid")
  address               Json?                                 // { street, city, province, postalCode }
  // Stripe customer ID — one customer per school across all lifecycle events.
  // 3NF: stripeCustomerId depends on the school, not on any individual subscription row.
  // Webhook receiver looks up school by this field directly.
  stripeCustomerId      String?            @unique @map("stripe_customer_id")
  // Denormalized from the active Subscription row — updated by Stripe webhooks.
  // Kept here for fast RLS checks and JWT injection without a join.
  subscriptionStatus    SubscriptionStatus @default(TRIAL)    @map("subscription_status")
  dataRetentionDays     Int                @default(365)      @map("data_retention_days")
  // Communication hours — enforced server-side; parents see "outside hours" state
  commStartHour         Int                @default(7)        @map("comm_start_hour")   // 07:00
  commEndHour           Int                @default(19)       @map("comm_end_hour")     // 19:00
  // Safeguarding: alert Carmen if child absent with no parent notification by this hour
  safeguardingAlertHour Int                @default(10)       @map("safeguarding_alert_hour")
  settings              Json               @default("{}")     // catch-all for school-specific config
  internalNotes         String?            @map("internal_notes")  // operator-only notes (support history, suspension reasons, etc.) — never exposed to school users
  createdAt             DateTime           @default(now())    @map("created_at") @db.Timestamptz
  updatedAt             DateTime           @updatedAt         @map("updated_at") @db.Timestamptz
  deletedAt             DateTime?          @map("deleted_at") @db.Timestamptz  // soft delete

  memberships       SchoolMembership[]
  subscriptions     Subscription[]
  classrooms        Classroom[]
  classroomStaff    ClassroomStaff[]
  children          Child[]
  parentChildLinks  ParentChildLink[]
  dailyReports      DailyReport[]
  media             Media[]
  messages          Message[]
  messageReceipts   MessageReceipt[]
  attendanceRecords AttendanceRecord[]
  consentRecords    ConsentRecord[]
  auditEvents       AuditEvent[]

  @@map("schools")
}

// ─── Subscriptions ───────────────────────────────────────────────────────────
// One row per Stripe subscription object — keeps history across cancellations
// and re-subscriptions (important given the seasonal June/September churn pattern).
// Rows are MUTABLE: period dates update in place on invoice events.
// stripeCustomerId lives on School (it belongs to the school, not to an individual subscription).
//
// schools.subscription_status is a denormalized copy of the latest row's status.
// Stripe webhooks update both in the same transaction.
//
// Webhook → field mapping:
//   customer.subscription.created  → new row, status=ACTIVE
//   invoice.payment_succeeded      → update current_period_start/end
//   invoice.payment_failed         → status=SUSPENDED
//   customer.subscription.deleted  → status=CANCELLED, cancelled_at=now()

model Subscription {
  id                   String             @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId             String             @map("school_id") @db.Uuid
  stripeSubscriptionId String?            @unique @map("stripe_subscription_id")
  stripePriceId        String?            @map("stripe_price_id")
  status               SubscriptionStatus
  trialEndsAt          DateTime?          @map("trial_ends_at") @db.Timestamptz
  currentPeriodStart   DateTime?          @map("current_period_start") @db.Timestamptz
  currentPeriodEnd     DateTime?          @map("current_period_end") @db.Timestamptz
  cancelledAt          DateTime?          @map("cancelled_at") @db.Timestamptz
  createdAt            DateTime           @default(now()) @map("created_at") @db.Timestamptz
  updatedAt            DateTime           @updatedAt      @map("updated_at") @db.Timestamptz

  school School @relation(fields: [schoolId], references: [id])

  @@index([schoolId])
  @@map("subscriptions")
}

// ─── Users (identity only) ────────────────────────────────────────────────────
// Supabase Auth owns the auth.users table (email, password hash, OAuth tokens, sessions).
// This table is our application profile — identity only, no school or role here.
//
// Role and school context live in SchoolMembership, allowing one user to belong
// to multiple schools with different roles (e.g. a director who owns two schools,
// a teacher who substitutes at two locations).
//
// The FK to auth.users cannot be declared in Prisma (different schema).
// Add it manually in the migration:
//   ALTER TABLE users ADD CONSTRAINT fk_auth_user
//     FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;

model User {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  authId    String   @unique @map("auth_id") @db.Uuid  // references auth.users(id)
  firstName String   @map("first_name")
  lastName  String   @map("last_name")
  phone     String?
  locale    String   @default("es")
  active    Boolean  @default(true)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz
  updatedAt DateTime @updatedAt      @map("updated_at") @db.Timestamptz

  memberships            SchoolMembership[]
  devicePushTokens       DevicePushToken[]
  notificationPrefs      NotificationPreference[]
  classroomAssignments   ClassroomStaff[]
  parentChildLinks       ParentChildLink[]
  sentMessages           Message[]               @relation("MessageSender")
  receivedDirectMessages Message[]               @relation("DirectMessageTarget")
  messageReceipts        MessageReceipt[]
  consentRecordsGranted  ConsentRecord[]
  uploadedMedia          Media[]
  taggedMedia            MediaChildTag[]         @relation("MediaTagger")
  createdDailyReports    DailyReport[]
  auditEvents            AuditEvent[]            @relation("AuditActor")

  @@map("users")
}

// ─── School Memberships ───────────────────────────────────────────────────────
// One row per (user, school) pair. Role lives here, not on User.
// A director who owns two schools has two rows — one per school.
// A teacher who substitutes at two schools also has two rows.
//
// School switching (multi-school users):
//   1. User logs in — JWT hook fetches memberships
//   2. If one membership → inject school_id + role into JWT automatically
//   3. If multiple → app shows school picker; user selects one
//   4. API call sets is_active = true on chosen membership (flips others to false)
//   5. Client calls supabase.auth.refreshSession() → JWT hook re-runs → new JWT
//      with the selected school's school_id + role baked in
//   6. All subsequent requests and RLS policies use the new school context

model SchoolMembership {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId    String   @map("user_id") @db.Uuid
  schoolId  String   @map("school_id") @db.Uuid
  role      UserRole
  isActive  Boolean  @default(true) @map("is_active")  // active school context for this user
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz

  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
  school School @relation(fields: [schoolId], references: [id])

  @@unique([userId, schoolId])
  @@index([schoolId, role])
  @@map("school_memberships")
}

model DevicePushToken {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId    String   @map("user_id") @db.Uuid
  token     String       @unique      // Expo push token or raw FCM token
  platform  PushPlatform              // DB-enforced enum: IOS | ANDROID | WEB
  active    Boolean  @default(true)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz
  updatedAt DateTime @updatedAt      @map("updated_at") @db.Timestamptz

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@map("device_push_tokens")
}

model NotificationPreference {
  id     String           @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId String           @map("user_id") @db.Uuid
  type   NotificationType // DB-enforced enum
  push   Boolean @default(true)
  email  Boolean @default(false)
  sms    Boolean @default(false)

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, type])
  @@map("notification_preferences")
}

// ─── Classrooms ───────────────────────────────────────────────────────────────

model Classroom {
  id          String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId    String   @map("school_id") @db.Uuid
  name        String                              // "Sala 1–2 años", "Sala 2–3 años"
  ageGroupMin Int?     @map("age_group_min")     // in months; optional metadata
  ageGroupMax Int?     @map("age_group_max")
  capacity    Int?
  active      Boolean  @default(true)
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz
  updatedAt   DateTime @updatedAt      @map("updated_at") @db.Timestamptz

  school            School             @relation(fields: [schoolId], references: [id])
  children          Child[]
  staff             ClassroomStaff[]
  dailyReports      DailyReport[]
  attendanceRecords AttendanceRecord[]
  broadcastMessages Message[]          @relation("ClassroomBroadcastTarget")

  @@index([schoolId])
  @@map("classrooms")
}

// Many-to-many: which staff members are assigned to which classrooms
// schoolId is denormalized from classroom.schoolId for RLS — do not derive at query time.
model ClassroomStaff {
  classroomId String   @map("classroom_id") @db.Uuid
  userId      String   @map("user_id") @db.Uuid
  schoolId    String   @map("school_id") @db.Uuid  // RLS anchor — denormed from classroom.schoolId
  isPrimary   Boolean  @default(false) @map("is_primary")  // lead teacher flag
  assignedAt  DateTime @default(now()) @map("assigned_at") @db.Timestamptz

  classroom Classroom @relation(fields: [classroomId], references: [id])
  user      User      @relation(fields: [userId], references: [id])
  school    School    @relation(fields: [schoolId], references: [id])

  @@id([classroomId, userId])
  @@index([schoolId])
  @@map("classroom_staff")
}

// ─── Children ─────────────────────────────────────────────────────────────────

model Child {
  id          String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid
  classroomId String?   @map("classroom_id") @db.Uuid  // null if not yet assigned
  firstName   String    @map("first_name")
  lastName    String    @map("last_name")
  dateOfBirth DateTime  @map("date_of_birth") @db.Date
  // Sensitive fields — encrypt at application layer before writing (AES-256-GCM)
  medicalNotes  String? @map("medical_notes")
  dietaryNotes  String? @map("dietary_notes")
  active      Boolean   @default(true)
  enrolledAt  DateTime  @map("enrolled_at") @db.Date
  leftAt      DateTime? @map("left_at") @db.Date
  createdAt   DateTime  @default(now()) @map("created_at") @db.Timestamptz
  updatedAt   DateTime  @updatedAt      @map("updated_at") @db.Timestamptz

  school             School             @relation(fields: [schoolId], references: [id])
  classroom          Classroom?         @relation(fields: [classroomId], references: [id])
  parentLinks        ParentChildLink[]
  consentRecords     ConsentRecord[]
  attendanceRecords  AttendanceRecord[]
  activityLogEntries ActivityLogEntry[]
  mediaTags          MediaChildTag[]

  @@index([schoolId])
  @@index([classroomId])
  @@map("children")
}

// Open join table — no maximum guardians per child
// schoolId is denormalized from child.schoolId for RLS — do not derive at query time.
model ParentChildLink {
  id           String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId       String   @map("user_id") @db.Uuid    // user must have a SchoolMembership with role=PARENT for this school
  childId      String   @map("child_id") @db.Uuid
  schoolId     String   @map("school_id") @db.Uuid  // RLS anchor — denormed from child.schoolId
  relationship String?                               // 'mother' | 'father' | 'guardian' | 'grandparent'
  isPrimary    Boolean  @default(false) @map("is_primary")  // primary contact
  active       Boolean  @default(true)
  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamptz

  user   User   @relation(fields: [userId], references: [id])
  child  Child  @relation(fields: [childId], references: [id])
  school School @relation(fields: [schoolId], references: [id])

  @@unique([userId, childId])
  @@index([childId])
  @@index([schoolId])
  @@map("parent_child_links")
}

// ─── Consent ─────────────────────────────────────────────────────────────────
// One row per consent event. Status changes (revoke, re-grant) add new rows.
// Current consent = latest row per (child_id, consent_type).

model ConsentRecord {
  id                 String        @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId           String        @map("school_id") @db.Uuid
  childId            String        @map("child_id") @db.Uuid
  grantedByUserId    String        @map("granted_by_user_id") @db.Uuid
  consentType        ConsentType   @map("consent_type")
  status             ConsentStatus @default(GRANTED)
  consentTextVersion String        @map("consent_text_version")  // version of legal text shown
  grantedAt          DateTime      @default(now()) @map("granted_at") @db.Timestamptz
  revokedAt          DateTime?     @map("revoked_at") @db.Timestamptz
  revocationReason   String?       @map("revocation_reason")
  // GDPR proof-of-consent fields
  ipAddress          String?       @map("ip_address")
  userAgent          String?       @map("user_agent")

  school        School        @relation(fields: [schoolId], references: [id])
  child         Child         @relation(fields: [childId], references: [id])
  grantedByUser User          @relation(fields: [grantedByUserId], references: [id])
  mediaTags     MediaChildTag[]

  @@index([childId, consentType, status])
  @@map("consent_records")
}

// ─── Daily Reports ────────────────────────────────────────────────────────────
// One report per classroom per day. Class-level fields are defaults.
// ActivityLogEntry holds per-child overrides (null = inherit class default).

model DailyReport {
  id              String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId        String    @map("school_id") @db.Uuid
  classroomId     String    @map("classroom_id") @db.Uuid
  reportDate      DateTime  @map("report_date") @db.Date
  createdById     String    @map("created_by_id") @db.Uuid
  // null = draft (not visible to parents); set = published (triggers push notifications)
  publishedAt     DateTime? @map("published_at") @db.Timestamptz
  // Class-level defaults (visible to all families unless overridden per child)
  classSummary    String?     @map("class_summary")
  classMealStatus MealStatus? @map("class_meal_status")
  classNapMinutes Int?        @map("class_nap_minutes")
  classMood       MoodStatus? @map("class_mood")
  createdAt       DateTime  @default(now()) @map("created_at") @db.Timestamptz
  updatedAt       DateTime  @updatedAt      @map("updated_at") @db.Timestamptz

  school             School             @relation(fields: [schoolId], references: [id])
  classroom          Classroom          @relation(fields: [classroomId], references: [id])
  createdBy          User               @relation(fields: [createdById], references: [id])
  activityLogEntries ActivityLogEntry[]
  media              Media[]

  @@unique([classroomId, reportDate])
  @@index([schoolId, reportDate])
  @@map("daily_reports")
}

// Per-child overrides. A null field means "show the class-level default to this parent".
// schoolId is denormalized from dailyReport.schoolId for RLS (no join in policy).
// Trigger in raw migration validates: NEW.school_id = daily_reports.school_id WHERE id = NEW.daily_report_id
model ActivityLogEntry {
  id            String      @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId      String      @map("school_id") @db.Uuid  // RLS anchor — denormed from dailyReport.schoolId
  dailyReportId String      @map("daily_report_id") @db.Uuid
  childId       String      @map("child_id") @db.Uuid
  mealStatus    MealStatus? @map("meal_status")   // null = inherit class default
  napMinutes    Int?        @map("nap_minutes")
  mood          MoodStatus?
  // Two note fields: only parentMessage is shown to parents
  notes         String?                            // internal teacher notes
  parentMessage String?     @map("parent_message") // shown in parent's child view
  createdAt     DateTime  @default(now()) @map("created_at") @db.Timestamptz
  updatedAt     DateTime  @updatedAt      @map("updated_at") @db.Timestamptz

  dailyReport DailyReport @relation(fields: [dailyReportId], references: [id])
  child       Child       @relation(fields: [childId], references: [id])

  @@unique([dailyReportId, childId])
  @@map("activity_log_entries")
}

// ─── Media ────────────────────────────────────────────────────────────────────
// Photos and videos stored in Tigris (EU S3-compatible).
// Never serve media directly — always via server-generated 15-min signed URLs.
// Client uploads directly to Tigris via pre-signed upload URL (server never proxies the file).

model Media {
  id                String                @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId          String                @map("school_id") @db.Uuid
  dailyReportId     String?               @map("daily_report_id") @db.Uuid  // nullable: standalone media
  uploadedById      String                @map("uploaded_by_id") @db.Uuid
  type              MediaType
  storageKey        String                @unique @map("storage_key")        // opaque UUID key in Tigris bucket
  originalFilename  String?               @map("original_filename")           // stored for audit only
  fileSizeBytes     BigInt?               @map("file_size_bytes")
  durationSeconds   Int?                  @map("duration_seconds")            // video only
  processingStatus  MediaProcessingStatus @default(PENDING) @map("processing_status")
  takenAt           DateTime?             @map("taken_at") @db.Timestamptz    // EXIF or client-reported
  deleteAfter       DateTime?             @map("delete_after") @db.Timestamptz // from school retention policy
  deletedAt         DateTime?             @map("deleted_at") @db.Timestamptz  // soft delete before storage deletion
  createdAt         DateTime              @default(now()) @map("created_at") @db.Timestamptz

  school      School          @relation(fields: [schoolId], references: [id])
  dailyReport DailyReport?    @relation(fields: [dailyReportId], references: [id])
  uploadedBy  User            @relation(fields: [uploadedById], references: [id])
  childTags   MediaChildTag[]

  @@index([schoolId, dailyReportId])
  @@map("media")
}

// Tagging a child in a photo/video. Enforced by:
//   1. Application layer: consent check before insert
//   2. PostgreSQL trigger: validates consent_records row before insert (defense-in-depth)
//   3. Signed URL generation: re-checks consent before serving (even for previously-tagged media)
model MediaChildTag {
  id                String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  mediaId           String   @map("media_id") @db.Uuid
  childId           String   @map("child_id") @db.Uuid
  schoolId          String   @map("school_id") @db.Uuid
  taggedById        String   @map("tagged_by_id") @db.Uuid
  consentVerifiedAt DateTime @map("consent_verified_at") @db.Timestamptz  // snapshot of when consent was checked
  consentRecordId   String   @map("consent_record_id") @db.Uuid           // FK to the specific consent row used
  createdAt         DateTime @default(now()) @map("created_at") @db.Timestamptz

  media         Media         @relation(fields: [mediaId], references: [id])
  child         Child         @relation(fields: [childId], references: [id])
  taggedBy      User          @relation("MediaTagger", fields: [taggedById], references: [id])
  consentRecord ConsentRecord @relation(fields: [consentRecordId], references: [id])

  @@unique([mediaId, childId])
  @@map("media_child_tags")
}

// ─── Messaging ────────────────────────────────────────────────────────────────
// DIRECT: one staff ↔ one parent thread
// CLASS_BROADCAST: staff → all parents in classroom (parents cannot reply-all)
// SCHOOL_BROADCAST: director → all school parents (target_classroom_id null, school_id is the target)

model Message {
  id                String      @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId          String      @map("school_id") @db.Uuid
  senderId          String      @map("sender_id") @db.Uuid
  threadId          String?     @map("thread_id") @db.Uuid         // null = root message; set = reply
  type              MessageType
  // Exactly one target field set depending on type:
  targetUserId      String?     @map("target_user_id") @db.Uuid      // DIRECT
  targetClassroomId String?     @map("target_classroom_id") @db.Uuid // CLASS_BROADCAST
  // SCHOOL_BROADCAST: no extra target field; school_id is sufficient
  body              String
  sentAt            DateTime    @default(now()) @map("sent_at") @db.Timestamptz
  // null = do not auto-delete; set at send time from school.dataRetentionDays snapshot
  deleteAfter       DateTime?   @map("delete_after") @db.Timestamptz
  deletedAt         DateTime?   @map("deleted_at") @db.Timestamptz
  // createdAt removed — sentAt is the canonical timestamp for this domain

  school          School           @relation(fields: [schoolId], references: [id])
  sender          User             @relation("MessageSender", fields: [senderId], references: [id])
  targetUser      User?            @relation("DirectMessageTarget", fields: [targetUserId], references: [id])
  targetClassroom Classroom?       @relation("ClassroomBroadcastTarget", fields: [targetClassroomId], references: [id])
  receipts        MessageReceipt[]
  thread          Message?         @relation("MessageThread", fields: [threadId], references: [id])
  replies         Message[]        @relation("MessageThread")

  @@index([schoolId, senderId])
  @@index([targetUserId])
  @@index([threadId])
  @@map("messages")
}

// One row per recipient per message. Fan-out on send (BullMQ job).
// schoolId denormed from message.schoolId for RLS — populated at fan-out time.
model MessageReceipt {
  messageId   String    @map("message_id") @db.Uuid
  userId      String    @map("user_id") @db.Uuid
  schoolId    String    @map("school_id") @db.Uuid  // RLS anchor — denormed from message.schoolId
  deliveredAt DateTime? @map("delivered_at") @db.Timestamptz
  readAt      DateTime? @map("read_at") @db.Timestamptz

  message Message @relation(fields: [messageId], references: [id])
  user    User    @relation(fields: [userId], references: [id])
  school  School  @relation(fields: [schoolId], references: [id])

  @@id([messageId, userId])
  @@index([schoolId])
  @@map("message_receipts")
}

// ─── Attendance ───────────────────────────────────────────────────────────────

model AttendanceRecord {
  id                    String           @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId              String           @map("school_id") @db.Uuid
  childId               String           @map("child_id") @db.Uuid
  // Snapshot of child.classroomId at the time of record. Not guaranteed to match
  // child.classroomId if the child later moves classrooms. Do not derive at query time.
  classroomId           String           @map("classroom_id") @db.Uuid
  date                  DateTime         @db.Date
  status                AttendanceStatus
  absenceReason         AbsenceReason?   @map("absence_reason")
  absenceNote           String?          @map("absence_note")                       // free text
  parentNotifiedAt      DateTime?        @map("parent_notified_at") @db.Timestamptz // parent submitted absence notification
  safeguardingAlertedAt DateTime?        @map("safeguarding_alerted_at") @db.Timestamptz // Feature 4.5
  createdAt             DateTime         @default(now()) @map("created_at") @db.Timestamptz
  updatedAt             DateTime         @updatedAt      @map("updated_at") @db.Timestamptz

  school    School    @relation(fields: [schoolId], references: [id])
  child     Child     @relation(fields: [childId], references: [id])
  classroom Classroom @relation(fields: [classroomId], references: [id])

  @@unique([childId, date])
  @@index([schoolId, date])
  @@map("attendance_records")
}

// ─── Audit ────────────────────────────────────────────────────────────────────
// Append-only. Never update or delete rows.
// Add range partitioning by occurred_at (monthly) in the initial migration SQL — Prisma does not
// support declarative partitioning, so write the partition DDL in the raw migration file.
//
// Event type catalog (non-exhaustive):
//   user.login | user.logout
//   media.viewed | media.uploaded
//   child.tagged | consent.granted | consent.revoked
//   report.published | message.sent
//   attendance.marked | safeguarding.alert
//   gdpr.erasure_request | gdpr.erasure_completed | data.exported

model AuditEvent {
  id           String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId     String    @map("school_id") @db.Uuid
  occurredAt   DateTime  @default(now()) @map("occurred_at") @db.Timestamptz
  actorId      String?    @map("actor_id") @db.Uuid   // null for system-initiated events
  actorType    ActorType? @map("actor_type")            // SYSTEM when actorId is null
  eventType    String    @map("event_type")
  resourceType String?   @map("resource_type")
  resourceId   String?   @map("resource_id") @db.Uuid
  metadata     Json      @default("{}")
  ipAddress    String?   @map("ip_address")
  userAgent    String?   @map("user_agent")

  school School @relation(fields: [schoolId], references: [id])
  actor  User?  @relation("AuditActor", fields: [actorId], references: [id])

  @@index([schoolId, occurredAt])
  @@index([schoolId, eventType])
  @@map("audit_events")
}
```

---

## Supabase Auth Integration

### Custom JWT Claims Hook

Supabase Auth issues JWTs. For RLS to work, each JWT must carry `school_id` and `role` as custom claims. Add this hook in Supabase Dashboard → Auth → Hooks:

```sql
-- Runs on every token issue and refresh.
-- Reads the active school membership for this user and injects school_id + role into the JWT.
-- If the user has multiple memberships, only the one with is_active = true is used.
-- If no active membership exists yet (e.g. invite just accepted), claims are omitted
-- and the app must prompt the user to select a school.
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb language plpgsql stable as $$
declare
  claims     jsonb;
  membership record;
begin
  select school_id, role
    into membership
    from public.school_memberships
   where user_id = (
           select id from public.users
            where auth_id = (event ->> 'user_id')::uuid
         )
     and is_active = true
   limit 1;

  claims := event -> 'claims';

  if membership is not null then
    claims := jsonb_set(claims, '{school_id}', to_jsonb(membership.school_id::text));
    claims := jsonb_set(claims, '{role}',      to_jsonb(membership.role::text));
  end if;

  return jsonb_set(event, '{claims}', claims);
end;
$$;

grant execute on function public.custom_access_token_hook to supabase_auth_admin;
```

The JWT now contains `role` and `school_id` from the active membership. These are available in RLS policies via `auth.jwt()`.

### User Creation Flow

When Supabase Auth creates a new user (sign-up or invite), a `public.users` row must be created immediately. Use a Postgres trigger on `auth.users`:

```sql
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer as $$
declare
  new_user_id uuid;
begin
  -- 1. Create the identity row (no school or role here)
  insert into public.users (auth_id, first_name, last_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name',  '')
  )
  returning id into new_user_id;

  -- 2. Create the school membership row if school_id + role were passed
  --    (they always are for invite flow; may be absent for self-sign-up if you add that later)
  if (new.raw_user_meta_data ->> 'school_id') is not null then
    insert into public.school_memberships (user_id, school_id, role, is_active)
    values (
      new_user_id,
      (new.raw_user_meta_data ->> 'school_id')::uuid,
      (new.raw_user_meta_data ->> 'role')::public."UserRole",
      true
    );
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_auth_user();
```

### Invite Flow (Director adds staff or parents)

1. Director submits new user form (email, role, first/last name)
2. Server calls `supabase.auth.admin.inviteUserByEmail(email, { data: { school_id, role, first_name, last_name } })`
3. Supabase sends the invite email; user sets their password via the Supabase-hosted link
4. On confirmation, the trigger above fires: creates the `public.users` row, then the `school_memberships` row
5. For social login: user signs in with Google/Apple instead of setting a password — trigger still fires on the first sign-in
6. **Existing user invited to a second school:** if `auth.users` row already exists (same email), the trigger does not fire again. The server must detect this case and insert the `school_memberships` row directly via the admin API.

### Social Login

Enable Google and Apple providers in Supabase Dashboard → Auth → Providers. No extra schema changes needed — Supabase Auth handles OAuth tokens. The trigger above fires regardless of the sign-in method.

---

## Row-Level Security

RLS policies read `school_id` and `role` directly from the JWT — no session variable needed. The Supabase client sends the JWT automatically; RLS evaluates it per query.

Example policy (apply to all tables with `school_id`):

```sql
ALTER TABLE children ENABLE ROW LEVEL SECURITY;

-- Users can only see children in their own school
CREATE POLICY school_isolation ON children
  USING (school_id = (auth.jwt() ->> 'school_id')::uuid);

-- Parents can only see children they are linked to
CREATE POLICY parent_child_access ON children
  USING (
    (auth.jwt() ->> 'role') IN ('DIRECTOR', 'TEACHER')
    OR EXISTS (
      SELECT 1 FROM parent_child_links
       WHERE parent_child_links.child_id = children.id
         AND parent_child_links.user_id = (
           SELECT id FROM users WHERE auth_id = auth.uid()
         )
         AND parent_child_links.active = true
    )
  );
```

In Prisma, use the Supabase client's auth headers rather than raw session variables. For server-side operations that bypass RLS (e.g. BullMQ workers), use the service role key — never expose it to clients.

---

## Indexes to Add in Raw Migration

Prisma `@@index` covers the common cases. Add these in the initial migration SQL file for performance and correctness:

```sql
-- ─── Partial indexes ─────────────────────────────────────────────────────────

-- Active children only (most teacher queries filter here)
CREATE INDEX idx_children_active ON children (school_id, classroom_id)
  WHERE active = true;

-- Published reports only (parent feed query)
CREATE INDEX idx_daily_reports_published ON daily_reports (classroom_id, report_date)
  WHERE published_at IS NOT NULL;

-- Unread receipts (dashboard unread badge query)
CREATE INDEX idx_message_receipts_unread ON message_receipts (message_id)
  WHERE read_at IS NULL;

-- Media available to serve (excludes deleted and still-processing)
CREATE INDEX idx_media_available ON media (school_id, daily_report_id)
  WHERE deleted_at IS NULL AND processing_status = 'READY';

-- ─── Covering index ───────────────────────────────────────────────────────────

-- "Latest consent for a child and type" query (avoids post-scan sort)
CREATE INDEX idx_consent_latest ON consent_records (child_id, consent_type, granted_at DESC);

-- ─── Uniqueness constraints ───────────────────────────────────────────────────

-- Prevents race condition where two concurrent school-switch requests both succeed.
-- Turning it into a constraint violation on the losing writer is the correct outcome.
CREATE UNIQUE INDEX uq_active_membership_per_user
  ON school_memberships (user_id)
  WHERE is_active = true;

-- ─── CHECK constraints ────────────────────────────────────────────────────────

-- Communication hour bounds
ALTER TABLE schools
  ADD CONSTRAINT chk_comm_hours
  CHECK (
    comm_start_hour >= 0 AND comm_start_hour <= 23 AND
    comm_end_hour   >= 0 AND comm_end_hour   <= 23 AND
    safeguarding_alert_hour >= 0 AND safeguarding_alert_hour <= 23
  );

-- Consent status/revokedAt consistency — prevents GDPR audit ambiguity
ALTER TABLE consent_records
  ADD CONSTRAINT chk_consent_status_consistency
  CHECK (
    (status = 'GRANTED' AND revoked_at IS NULL) OR
    (status = 'REVOKED' AND revoked_at IS NOT NULL)
  );

-- AuditEvent actor null consistency — system events have no actor_id
ALTER TABLE audit_events
  ADD CONSTRAINT chk_audit_actor_consistency
  CHECK (
    (actor_id IS NULL     AND actor_type = 'SYSTEM') OR
    (actor_id IS NOT NULL AND actor_type IN ('STAFF', 'PARENT'))
  );

-- Message deleteAfter must be in the future relative to sent time
ALTER TABLE messages
  ADD CONSTRAINT chk_message_delete_after
  CHECK (delete_after IS NULL OR delete_after > sent_at);

-- Media deleteAfter must be in the future relative to creation
ALTER TABLE media
  ADD CONSTRAINT chk_media_delete_after
  CHECK (delete_after IS NULL OR delete_after > created_at);

-- ─── Triggers ─────────────────────────────────────────────────────────────────

-- ActivityLogEntry.school_id must match its DailyReport.school_id
CREATE OR REPLACE FUNCTION validate_activity_log_school()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT school_id FROM daily_reports WHERE id = NEW.daily_report_id) <> NEW.school_id THEN
    RAISE EXCEPTION 'activity_log_entries.school_id does not match daily_reports.school_id';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_activity_log_school_check
  BEFORE INSERT OR UPDATE ON activity_log_entries
  FOR EACH ROW EXECUTE FUNCTION validate_activity_log_school();

-- MediaChildTag: consent_record must belong to the same child being tagged
CREATE OR REPLACE FUNCTION validate_media_tag_consent()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT child_id FROM consent_records WHERE id = NEW.consent_record_id) <> NEW.child_id THEN
    RAISE EXCEPTION 'media_child_tags.consent_record_id does not belong to the tagged child';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_media_tag_consent_check
  BEFORE INSERT ON media_child_tags
  FOR EACH ROW EXECUTE FUNCTION validate_media_tag_consent();

-- ─── Partition (audit_events) ─────────────────────────────────────────────────
-- See partition DDL comment on AuditEvent model above.
-- Create the parent table as PARTITION BY RANGE (occurred_at) and add monthly
-- child partitions in the migration file. Prisma does not manage partitions.
```

---

## Super Admin / Internal Operations

There is no `SUPER_ADMIN` role in the app. Platform-level operations (creating schools, managing subscriptions, debugging, GDPR erasures) use the **Supabase service role key**, which bypasses RLS entirely at the DB level.

```
Regular app users   →  anon key + JWT          →  RLS enforced per school
BullMQ workers      →  service role key         →  RLS bypassed
Admin panel / ops   →  service role key         →  RLS bypassed
```

**Why not a SUPER_ADMIN role in the JWT:**
Adding it requires every RLS policy to include a `OR role = 'SUPER_ADMIN'` clause. One compromised token = access to every school's data. The service role key is server-side only and never reaches a client.

**Auth for the admin panel:**
The service role key is a secret environment variable (`SUPABASE_SERVICE_ROLE_KEY`). The admin panel (or scripts) run server-side only and are protected separately — HTTP basic auth or a hardcoded operator token is sufficient for V1. Never expose the service role key to the browser or mobile app.

**Operations and the tool to use at each stage:**

| Stage | Tool | Notes |
|---|---|---|
| Now → first 20 schools | Supabase Studio | Free, already available — table editor + SQL console is enough |
| V1 (20–50 schools) | Server-side scripts + simple `/internal` Next.js routes | Protected by a secret header; use service role key for all DB calls |
| V2 (50+ schools) | Retool or Appsmith connected to your DB + API | Low build effort, good enough for a small ops team |

**Operations the admin panel will need:**

- Create a school: `INSERT INTO schools` + `supabase.auth.admin.inviteUserByEmail()` for the director
- Suspend / reactivate: `UPDATE schools SET subscription_status = 'SUSPENDED'`
- GDPR erasure: trigger the erasure BullMQ job for a given `school_id` or `user_id`
- Impersonate a school for debugging: `supabase.auth.admin.generateLink()` scoped to that school's director account
- View `internal_notes` on any school: only visible via service role key — never returned to school users

---

## Not In This Schema (Deferred)

| Entity | When to Add |
|---|---|
| `reminders` table (Differentiator 6 — Recordatorios) | V1.1 — scheduling logic on top of existing notification infra |
| `fee_records` | V2 prerequisite for Modelo 233 auto-generation (monthly fee per family, separate from Stripe subscription) |
| `classroom_enrollments` (history) | When mid-year classroom moves become a real operational need |
| `analytics_events` | V2 director dashboard — use `audit_events` for instrumentation in V1 |
| `feature_flags` table | Add when you have more than one gated feature; `schools.settings` JSON is sufficient for V1 |
