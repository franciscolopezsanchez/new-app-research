# Database Schema — Prisma
**Product Area**: Technical
**Last Updated**: 2026-04-14
**Version**: 1.1
**Status**: Draft — V1 scope

---

## Design Decisions

| Decision | Choice | Reason |
|---|---|---|
| ORM | Prisma | TypeScript-first, clean migration tooling, Supabase compatible |
| Auth | Supabase Auth | Handles email/password, social login (Google, Apple), password reset, invite flows — no custom auth code |
| Identity model | Single `users` table with `role` field, linked to `auth.users` via `auth_id` | No separate staff/parent profile tables — role encodes the distinction |
| Tenant isolation | `school_id` on every table + PostgreSQL RLS | Defense-in-depth: custom JWT claim `school_id` injected at token issue; RLS blocks cross-tenant reads at DB level |
| UUIDs | `gen_random_uuid()` (PostgreSQL 16 built-in) | No pgcrypto extension needed, no sequential ID leakage |
| Classroom assignment | Simple FK on `children.classroom_id` | No history table in V1; add `classroom_enrollments` if mid-year moves become a requirement |
| Guardian limit | No maximum — `parent_child_links` is an open join table | Handles separated parents, shared custody, multiple guardians |
| Soft deletes | Only on `schools` and `media` | Schools: data must survive cancellation for GDPR export requests. Media: soft delete before storage deletion. Everything else: hard delete or `active` flag |
| Audit partitioning | Note-only in V1 | `audit_events` should be range-partitioned by `occurred_at` month via a raw SQL migration. Prisma does not support declarative partitioning — add this in the initial migration file manually |

---

## Entity Map

```
School (tenant root)
  ├── User (director | teacher | parent)          ← references auth.users via auth_id
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

// ─── School (Tenant Root) ─────────────────────────────────────────────────────

model School {
  id                    String             @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name                  String
  slug                  String             @unique            // URL identifier, e.g. "guarderia-pulgarcito"
  locale                String             @default("es")
  timezone              String             @default("Europe/Madrid")
  address               Json?                                 // { street, city, province, postalCode }
  subscriptionStatus    SubscriptionStatus @default(TRIAL)    @map("subscription_status")
  stripeCustomerId      String?            @map("stripe_customer_id")
  dataRetentionDays     Int                @default(365)      @map("data_retention_days")
  // Communication hours — enforced server-side; parents see "outside hours" state
  commStartHour         Int                @default(7)        @map("comm_start_hour")   // 07:00
  commEndHour           Int                @default(19)       @map("comm_end_hour")     // 19:00
  // Safeguarding: alert Carmen if child absent with no parent notification by this hour
  safeguardingAlertHour Int                @default(10)       @map("safeguarding_alert_hour")
  settings              Json               @default("{}")     // catch-all for school-specific config
  createdAt             DateTime           @default(now())    @map("created_at") @db.Timestamptz
  updatedAt             DateTime           @updatedAt         @map("updated_at") @db.Timestamptz
  deletedAt             DateTime?          @map("deleted_at") @db.Timestamptz  // soft delete

  users             User[]
  classrooms        Classroom[]
  children          Child[]
  dailyReports      DailyReport[]
  media             Media[]
  messages          Message[]
  attendanceRecords AttendanceRecord[]
  consentRecords    ConsentRecord[]
  auditEvents       AuditEvent[]

  @@map("schools")
}

// ─── Users (single identity table) ───────────────────────────────────────────
// Supabase Auth owns the auth.users table (email, password hash, OAuth tokens, sessions).
// This table is our application profile — it references auth.users via auth_id.
//
// role=DIRECTOR|TEACHER → assigned to classrooms via ClassroomStaff
// role=PARENT           → linked to children via ParentChildLink
//
// A user belongs to exactly one school in V1.
// If a parent has children at different schools, they create separate accounts.
//
// The FK to auth.users cannot be declared in Prisma (different schema).
// Add it manually in the migration:
//   ALTER TABLE users ADD CONSTRAINT fk_auth_user
//     FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;

model User {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  authId    String   @unique @map("auth_id") @db.Uuid  // references auth.users(id)
  schoolId  String   @map("school_id") @db.Uuid
  role      UserRole
  firstName String   @map("first_name")
  lastName  String   @map("last_name")
  phone     String?
  locale    String   @default("es")                    // parent's preferred language
  active    Boolean  @default(true)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz
  updatedAt DateTime @updatedAt      @map("updated_at") @db.Timestamptz

  school                 School                  @relation(fields: [schoolId], references: [id])
  devicePushTokens       DevicePushToken[]
  notificationPrefs      NotificationPreference[]
  classroomAssignments   ClassroomStaff[]        // populated for DIRECTOR and TEACHER
  parentChildLinks       ParentChildLink[]        // populated for PARENT
  sentMessages           Message[]               @relation("MessageSender")
  receivedDirectMessages Message[]               @relation("DirectMessageTarget")
  messageReceipts        MessageReceipt[]
  consentRecordsGranted  ConsentRecord[]
  uploadedMedia          Media[]
  taggedMedia            MediaChildTag[]         @relation("MediaTagger")
  createdDailyReports    DailyReport[]
  auditEvents            AuditEvent[]            @relation("AuditActor")

  @@index([schoolId, role])
  @@map("users")
}

model DevicePushToken {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId    String   @map("user_id") @db.Uuid
  token     String   @unique          // Expo push token or raw FCM token
  platform  String                    // 'ios' | 'android' | 'web'
  active    Boolean  @default(true)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz
  updatedAt DateTime @updatedAt      @map("updated_at") @db.Timestamptz

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@map("device_push_tokens")
}

model NotificationPreference {
  id     String  @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId String  @map("user_id") @db.Uuid
  // type: 'new_message' | 'daily_report' | 'new_photo' | 'attendance_alert' | 'safeguarding_alert'
  type   String
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
model ClassroomStaff {
  classroomId String   @map("classroom_id") @db.Uuid
  userId      String   @map("user_id") @db.Uuid
  isPrimary   Boolean  @default(false) @map("is_primary")  // lead teacher flag
  assignedAt  DateTime @default(now()) @map("assigned_at") @db.Timestamptz

  classroom Classroom @relation(fields: [classroomId], references: [id])
  user      User      @relation(fields: [userId], references: [id])

  @@id([classroomId, userId])
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
model ParentChildLink {
  id           String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId       String   @map("user_id") @db.Uuid    // must have role=PARENT
  childId      String   @map("child_id") @db.Uuid
  relationship String?                               // 'mother' | 'father' | 'guardian' | 'grandparent'
  isPrimary    Boolean  @default(false) @map("is_primary")  // primary contact
  active       Boolean  @default(true)
  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamptz

  user  User  @relation(fields: [userId], references: [id])
  child Child @relation(fields: [childId], references: [id])

  @@unique([userId, childId])
  @@index([childId])
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
  classSummary    String?   @map("class_summary")
  classMealStatus String?   @map("class_meal_status")   // 'good' | 'partial' | 'poor'
  classNapMinutes Int?      @map("class_nap_minutes")
  classMood       String?   @map("class_mood")           // 'happy' | 'calm' | 'tired' | 'difficult'
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
model ActivityLogEntry {
  id            String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId      String    @map("school_id") @db.Uuid
  dailyReportId String    @map("daily_report_id") @db.Uuid
  childId       String    @map("child_id") @db.Uuid
  mealStatus    String?   @map("meal_status")     // null = inherit class default
  napMinutes    Int?      @map("nap_minutes")
  mood          String?
  // Two note fields: only parentMessage is shown to parents
  notes         String?                            // internal teacher notes
  parentMessage String?   @map("parent_message")  // shown in parent's child view
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
  deleteAfter       DateTime    @map("delete_after") @db.Timestamptz // computed from school retention policy at send time
  deletedAt         DateTime?   @map("deleted_at") @db.Timestamptz
  createdAt         DateTime    @default(now()) @map("created_at") @db.Timestamptz

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
model MessageReceipt {
  messageId   String    @map("message_id") @db.Uuid
  userId      String    @map("user_id") @db.Uuid
  deliveredAt DateTime? @map("delivered_at") @db.Timestamptz
  readAt      DateTime? @map("read_at") @db.Timestamptz

  message Message @relation(fields: [messageId], references: [id])
  user    User    @relation(fields: [userId], references: [id])

  @@id([messageId, userId])
  @@map("message_receipts")
}

// ─── Attendance ───────────────────────────────────────────────────────────────

model AttendanceRecord {
  id                    String           @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  schoolId              String           @map("school_id") @db.Uuid
  childId               String           @map("child_id") @db.Uuid
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
  actorId      String?   @map("actor_id") @db.Uuid    // null for system-initiated events
  actorType    String?   @map("actor_type")            // 'staff' | 'parent' | 'system'
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
-- Injects school_id and role from our public.users table into the JWT.
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb language plpgsql stable as $$
declare
  claims jsonb;
  user_row record;
begin
  select role, school_id
    into user_row
    from public.users
   where auth_id = (event ->> 'user_id')::uuid;

  claims := event -> 'claims';
  claims := jsonb_set(claims, '{role}',      to_jsonb(user_row.role::text));
  claims := jsonb_set(claims, '{school_id}', to_jsonb(user_row.school_id::text));

  return jsonb_set(event, '{claims}', claims);
end;
$$;

grant execute on function public.custom_access_token_hook to supabase_auth_admin;
```

The JWT now contains `role` and `school_id`. These are available in RLS policies via `auth.jwt()`.

### User Creation Flow

When Supabase Auth creates a new user (sign-up or invite), a `public.users` row must be created immediately. Use a Postgres trigger on `auth.users`:

```sql
create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer as $$
begin
  -- school_id and role are passed as raw_user_meta_data during invite/sign-up
  insert into public.users (auth_id, school_id, role, first_name, last_name)
  values (
    new.id,
    (new.raw_user_meta_data ->> 'school_id')::uuid,
    (new.raw_user_meta_data ->> 'role')::public."UserRole",
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name',  '')
  );
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
4. On confirmation, the trigger above fires and creates the `public.users` row
5. For social login: user can sign in with Google/Apple instead of setting a password — trigger still fires

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

Prisma `@@index` covers the common cases. Add these in the initial migration SQL file for performance:

```sql
-- Partial index: only active children
CREATE INDEX idx_children_active ON children (school_id, classroom_id)
  WHERE active = true;

-- Partial index: published reports only (parent feed query)
CREATE INDEX idx_daily_reports_published ON daily_reports (classroom_id, report_date)
  WHERE published_at IS NOT NULL;

-- Partial index: unread receipts (dashboard query)
CREATE INDEX idx_message_receipts_unread ON message_receipts (message_id)
  WHERE read_at IS NULL;

-- Partial index: media not deleted and ready to serve
CREATE INDEX idx_media_available ON media (school_id, daily_report_id)
  WHERE deleted_at IS NULL AND processing_status = 'READY';
```

---

## Not In This Schema (Deferred)

| Entity | When to Add |
|---|---|
| `reminders` table (Differentiator 6 — Recordatorios) | V1.1 — scheduling logic on top of existing notification infra |
| `billing_records` / `fee_records` | V2 prerequisite for Modelo 233 auto-generation |
| `classroom_enrollments` (history) | When mid-year classroom moves become a real operational need |
| `analytics_events` | V2 director dashboard — use `audit_events` for instrumentation in V1 |
| `feature_flags` table | Add when you have more than one gated feature; `schools.settings` JSON is sufficient for V1 |
