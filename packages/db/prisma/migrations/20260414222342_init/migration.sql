-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('DIRECTOR', 'TEACHER', 'PARENT');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('TRIAL', 'ACTIVE', 'SUSPENDED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ConsentType" AS ENUM ('DATA_PROCESSING', 'PHOTO_SHARING', 'VIDEO_SHARING', 'RESEARCH');

-- CreateEnum
CREATE TYPE "ConsentStatus" AS ENUM ('GRANTED', 'REVOKED');

-- CreateEnum
CREATE TYPE "MessageType" AS ENUM ('DIRECT', 'CLASS_BROADCAST', 'SCHOOL_BROADCAST');

-- CreateEnum
CREATE TYPE "MediaType" AS ENUM ('PHOTO', 'VIDEO');

-- CreateEnum
CREATE TYPE "MediaProcessingStatus" AS ENUM ('PENDING', 'READY', 'FAILED');

-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('PRESENT', 'ABSENT', 'LATE');

-- CreateEnum
CREATE TYPE "AbsenceReason" AS ENUM ('SICK', 'FAMILY', 'UNKNOWN', 'OTHER');

-- CreateEnum
CREATE TYPE "PushPlatform" AS ENUM ('IOS', 'ANDROID', 'WEB');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('NEW_MESSAGE', 'DAILY_REPORT', 'NEW_PHOTO', 'ATTENDANCE_ALERT', 'SAFEGUARDING_ALERT');

-- CreateEnum
CREATE TYPE "MealStatus" AS ENUM ('GOOD', 'PARTIAL', 'POOR');

-- CreateEnum
CREATE TYPE "MoodStatus" AS ENUM ('HAPPY', 'CALM', 'TIRED', 'DIFFICULT');

-- CreateEnum
CREATE TYPE "ActorType" AS ENUM ('STAFF', 'PARENT', 'SYSTEM');

-- CreateTable
CREATE TABLE "schools" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "locale" TEXT NOT NULL DEFAULT 'es',
    "timezone" TEXT NOT NULL DEFAULT 'Europe/Madrid',
    "address" JSONB,
    "stripe_customer_id" TEXT,
    "subscription_status" "SubscriptionStatus" NOT NULL DEFAULT 'TRIAL',
    "data_retention_days" INTEGER NOT NULL DEFAULT 365,
    "comm_start_hour" INTEGER NOT NULL DEFAULT 7,
    "comm_end_hour" INTEGER NOT NULL DEFAULT 19,
    "safeguarding_alert_hour" INTEGER NOT NULL DEFAULT 10,
    "settings" JSONB NOT NULL DEFAULT '{}',
    "internal_notes" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,
    "deleted_at" TIMESTAMPTZ,

    CONSTRAINT "schools_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "stripe_subscription_id" TEXT,
    "stripe_price_id" TEXT,
    "status" "SubscriptionStatus" NOT NULL,
    "trial_ends_at" TIMESTAMPTZ,
    "current_period_start" TIMESTAMPTZ,
    "current_period_end" TIMESTAMPTZ,
    "cancelled_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "auth_id" UUID NOT NULL,
    "first_name" TEXT NOT NULL DEFAULT '',
    "last_name" TEXT NOT NULL DEFAULT '',
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "locale" TEXT NOT NULL DEFAULT 'es',
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "school_memberships" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "school_id" UUID NOT NULL,
    "role" "UserRole" NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "school_memberships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "device_push_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "platform" "PushPlatform" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "device_push_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification_preferences" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "type" "NotificationType" NOT NULL,
    "push" BOOLEAN NOT NULL DEFAULT true,
    "email" BOOLEAN NOT NULL DEFAULT false,
    "sms" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "notification_preferences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "classrooms" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "age_group_min" INTEGER,
    "age_group_max" INTEGER,
    "capacity" INTEGER,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "classrooms_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "classroom_staff" (
    "classroom_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "school_id" UUID NOT NULL,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "assigned_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "classroom_staff_pkey" PRIMARY KEY ("classroom_id","user_id")
);

-- CreateTable
CREATE TABLE "children" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "classroom_id" UUID,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "date_of_birth" DATE NOT NULL,
    "medical_notes" TEXT,
    "dietary_notes" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "enrolled_at" DATE NOT NULL,
    "left_at" DATE,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "children_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "parent_child_links" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "school_id" UUID NOT NULL,
    "relationship" TEXT,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "parent_child_links_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "consent_records" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "granted_by_user_id" UUID NOT NULL,
    "consent_type" "ConsentType" NOT NULL,
    "status" "ConsentStatus" NOT NULL DEFAULT 'GRANTED',
    "consent_text_version" TEXT NOT NULL,
    "granted_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revoked_at" TIMESTAMPTZ,
    "revocation_reason" TEXT,
    "ip_address" TEXT,
    "user_agent" TEXT,

    CONSTRAINT "consent_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_reports" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "classroom_id" UUID NOT NULL,
    "report_date" DATE NOT NULL,
    "created_by_id" UUID NOT NULL,
    "published_at" TIMESTAMPTZ,
    "class_summary" TEXT,
    "class_meal_status" "MealStatus",
    "class_nap_minutes" INTEGER,
    "class_mood" "MoodStatus",
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "daily_reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "activity_log_entries" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "daily_report_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "meal_status" "MealStatus",
    "nap_minutes" INTEGER,
    "mood" "MoodStatus",
    "notes" TEXT,
    "parent_message" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "activity_log_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "daily_report_id" UUID,
    "uploaded_by_id" UUID NOT NULL,
    "type" "MediaType" NOT NULL,
    "storage_key" TEXT NOT NULL,
    "original_filename" TEXT,
    "file_size_bytes" BIGINT,
    "duration_seconds" INTEGER,
    "processing_status" "MediaProcessingStatus" NOT NULL DEFAULT 'PENDING',
    "taken_at" TIMESTAMPTZ,
    "delete_after" TIMESTAMPTZ,
    "deleted_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_child_tags" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "media_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "school_id" UUID NOT NULL,
    "tagged_by_id" UUID NOT NULL,
    "consent_verified_at" TIMESTAMPTZ NOT NULL,
    "consent_record_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_child_tags_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "sender_id" UUID NOT NULL,
    "thread_id" UUID,
    "type" "MessageType" NOT NULL,
    "target_user_id" UUID,
    "target_classroom_id" UUID,
    "body" TEXT NOT NULL,
    "sent_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "delete_after" TIMESTAMPTZ,
    "deleted_at" TIMESTAMPTZ,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_receipts" (
    "message_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "school_id" UUID NOT NULL,
    "delivered_at" TIMESTAMPTZ,
    "read_at" TIMESTAMPTZ,

    CONSTRAINT "message_receipts_pkey" PRIMARY KEY ("message_id","user_id")
);

-- CreateTable
CREATE TABLE "attendance_records" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "classroom_id" UUID NOT NULL,
    "date" DATE NOT NULL,
    "status" "AttendanceStatus" NOT NULL,
    "absence_reason" "AbsenceReason",
    "absence_note" TEXT,
    "parent_notified_at" TIMESTAMPTZ,
    "safeguarding_alerted_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "attendance_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_events" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "school_id" UUID NOT NULL,
    "occurred_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actor_id" UUID,
    "actor_type" "ActorType",
    "event_type" TEXT NOT NULL,
    "resource_type" TEXT,
    "resource_id" UUID,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "ip_address" TEXT,
    "user_agent" TEXT,

    CONSTRAINT "audit_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "schools_slug_key" ON "schools"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "schools_stripe_customer_id_key" ON "schools"("stripe_customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_stripe_subscription_id_key" ON "subscriptions"("stripe_subscription_id");

-- CreateIndex
CREATE INDEX "subscriptions_school_id_idx" ON "subscriptions"("school_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_auth_id_key" ON "users"("auth_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "school_memberships_school_id_role_idx" ON "school_memberships"("school_id", "role");

-- CreateIndex
CREATE UNIQUE INDEX "school_memberships_user_id_school_id_key" ON "school_memberships"("user_id", "school_id");

-- CreateIndex
CREATE UNIQUE INDEX "device_push_tokens_token_key" ON "device_push_tokens"("token");

-- CreateIndex
CREATE INDEX "device_push_tokens_user_id_idx" ON "device_push_tokens"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "notification_preferences_user_id_type_key" ON "notification_preferences"("user_id", "type");

-- CreateIndex
CREATE INDEX "classrooms_school_id_idx" ON "classrooms"("school_id");

-- CreateIndex
CREATE INDEX "classroom_staff_school_id_idx" ON "classroom_staff"("school_id");

-- CreateIndex
CREATE INDEX "children_school_id_idx" ON "children"("school_id");

-- CreateIndex
CREATE INDEX "children_classroom_id_idx" ON "children"("classroom_id");

-- CreateIndex
CREATE INDEX "parent_child_links_child_id_idx" ON "parent_child_links"("child_id");

-- CreateIndex
CREATE INDEX "parent_child_links_school_id_idx" ON "parent_child_links"("school_id");

-- CreateIndex
CREATE UNIQUE INDEX "parent_child_links_user_id_child_id_key" ON "parent_child_links"("user_id", "child_id");

-- CreateIndex
CREATE INDEX "consent_records_child_id_consent_type_status_idx" ON "consent_records"("child_id", "consent_type", "status");

-- CreateIndex
CREATE INDEX "daily_reports_school_id_report_date_idx" ON "daily_reports"("school_id", "report_date");

-- CreateIndex
CREATE UNIQUE INDEX "daily_reports_classroom_id_report_date_key" ON "daily_reports"("classroom_id", "report_date");

-- CreateIndex
CREATE UNIQUE INDEX "activity_log_entries_daily_report_id_child_id_key" ON "activity_log_entries"("daily_report_id", "child_id");

-- CreateIndex
CREATE UNIQUE INDEX "media_storage_key_key" ON "media"("storage_key");

-- CreateIndex
CREATE INDEX "media_school_id_daily_report_id_idx" ON "media"("school_id", "daily_report_id");

-- CreateIndex
CREATE UNIQUE INDEX "media_child_tags_media_id_child_id_key" ON "media_child_tags"("media_id", "child_id");

-- CreateIndex
CREATE INDEX "messages_school_id_sender_id_idx" ON "messages"("school_id", "sender_id");

-- CreateIndex
CREATE INDEX "messages_target_user_id_idx" ON "messages"("target_user_id");

-- CreateIndex
CREATE INDEX "messages_thread_id_idx" ON "messages"("thread_id");

-- CreateIndex
CREATE INDEX "message_receipts_school_id_idx" ON "message_receipts"("school_id");

-- CreateIndex
CREATE INDEX "attendance_records_school_id_date_idx" ON "attendance_records"("school_id", "date");

-- CreateIndex
CREATE UNIQUE INDEX "attendance_records_child_id_date_key" ON "attendance_records"("child_id", "date");

-- CreateIndex
CREATE INDEX "audit_events_school_id_occurred_at_idx" ON "audit_events"("school_id", "occurred_at");

-- CreateIndex
CREATE INDEX "audit_events_school_id_event_type_idx" ON "audit_events"("school_id", "event_type");

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "school_memberships" ADD CONSTRAINT "school_memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "school_memberships" ADD CONSTRAINT "school_memberships_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "device_push_tokens" ADD CONSTRAINT "device_push_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_preferences" ADD CONSTRAINT "notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "classrooms" ADD CONSTRAINT "classrooms_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "classroom_staff" ADD CONSTRAINT "classroom_staff_classroom_id_fkey" FOREIGN KEY ("classroom_id") REFERENCES "classrooms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "classroom_staff" ADD CONSTRAINT "classroom_staff_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "classroom_staff" ADD CONSTRAINT "classroom_staff_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "children" ADD CONSTRAINT "children_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "children" ADD CONSTRAINT "children_classroom_id_fkey" FOREIGN KEY ("classroom_id") REFERENCES "classrooms"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "parent_child_links" ADD CONSTRAINT "parent_child_links_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "parent_child_links" ADD CONSTRAINT "parent_child_links_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "parent_child_links" ADD CONSTRAINT "parent_child_links_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consent_records" ADD CONSTRAINT "consent_records_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consent_records" ADD CONSTRAINT "consent_records_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consent_records" ADD CONSTRAINT "consent_records_granted_by_user_id_fkey" FOREIGN KEY ("granted_by_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_reports" ADD CONSTRAINT "daily_reports_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_reports" ADD CONSTRAINT "daily_reports_classroom_id_fkey" FOREIGN KEY ("classroom_id") REFERENCES "classrooms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_reports" ADD CONSTRAINT "daily_reports_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_log_entries" ADD CONSTRAINT "activity_log_entries_daily_report_id_fkey" FOREIGN KEY ("daily_report_id") REFERENCES "daily_reports"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_log_entries" ADD CONSTRAINT "activity_log_entries_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media" ADD CONSTRAINT "media_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media" ADD CONSTRAINT "media_daily_report_id_fkey" FOREIGN KEY ("daily_report_id") REFERENCES "daily_reports"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media" ADD CONSTRAINT "media_uploaded_by_id_fkey" FOREIGN KEY ("uploaded_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_child_tags" ADD CONSTRAINT "media_child_tags_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_child_tags" ADD CONSTRAINT "media_child_tags_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_child_tags" ADD CONSTRAINT "media_child_tags_tagged_by_id_fkey" FOREIGN KEY ("tagged_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_child_tags" ADD CONSTRAINT "media_child_tags_consent_record_id_fkey" FOREIGN KEY ("consent_record_id") REFERENCES "consent_records"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_target_user_id_fkey" FOREIGN KEY ("target_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_target_classroom_id_fkey" FOREIGN KEY ("target_classroom_id") REFERENCES "classrooms"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_thread_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "messages"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_receipts" ADD CONSTRAINT "message_receipts_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "messages"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_receipts" ADD CONSTRAINT "message_receipts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_receipts" ADD CONSTRAINT "message_receipts_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_classroom_id_fkey" FOREIGN KEY ("classroom_id") REFERENCES "classrooms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_events" ADD CONSTRAINT "audit_events_school_id_fkey" FOREIGN KEY ("school_id") REFERENCES "schools"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_events" ADD CONSTRAINT "audit_events_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- EXTRAS: triggers, RLS, indexes, constraints not expressible in Prisma schema
-- ─────────────────────────────────────────────────────────────────────────────

-- Cross-schema FK: users.auth_id → auth.users(id)
ALTER TABLE users
  ADD CONSTRAINT fk_auth_user
  FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- handle_new_auth_user: creates public.users + school_membership on signup/invite
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_user_id uuid;
BEGIN
  INSERT INTO public.users (auth_id, first_name, last_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'first_name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'last_name',  ''),
    COALESCE(NEW.email, '')
  )
  RETURNING id INTO new_user_id;

  IF (NEW.raw_user_meta_data ->> 'school_id') IS NOT NULL THEN
    INSERT INTO public.school_memberships (user_id, school_id, role, is_active)
    VALUES (
      new_user_id,
      (NEW.raw_user_meta_data ->> 'school_id')::uuid,
      (NEW.raw_user_meta_data ->> 'role')::public."UserRole",
      true
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_auth_user();

-- custom_access_token_hook: injects school_id + role into JWT
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb LANGUAGE plpgsql STABLE
SET search_path = public
AS $$
DECLARE
  claims     jsonb;
  membership record;
BEGIN
  SELECT school_id, role
    INTO membership
    FROM public.school_memberships
   WHERE user_id = (
           SELECT id FROM public.users
            WHERE auth_id = (event ->> 'user_id')::uuid
         )
     AND is_active = true
   LIMIT 1;

  claims := event -> 'claims';

  IF membership IS NOT NULL THEN
    claims := jsonb_set(claims, '{school_id}', to_jsonb(membership.school_id::text));
    claims := jsonb_set(claims, '{role}',      to_jsonb(membership.role::text));
  END IF;

  RETURN jsonb_set(event, '{claims}', claims);
END;
$$;

GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;

-- Partial indexes
CREATE INDEX idx_children_active ON children (school_id, classroom_id) WHERE active = true;
CREATE INDEX idx_daily_reports_published ON daily_reports (classroom_id, report_date) WHERE published_at IS NOT NULL;
CREATE INDEX idx_message_receipts_unread ON message_receipts (message_id) WHERE read_at IS NULL;
CREATE INDEX idx_media_available ON media (school_id, daily_report_id) WHERE deleted_at IS NULL AND processing_status = 'READY';
CREATE INDEX idx_consent_latest ON consent_records (child_id, consent_type, granted_at DESC);

-- Race-condition guard: only one active membership per user
CREATE UNIQUE INDEX uq_active_membership_per_user ON school_memberships (user_id) WHERE is_active = true;

-- CHECK constraints
ALTER TABLE schools ADD CONSTRAINT chk_comm_hours CHECK (
  comm_start_hour >= 0 AND comm_start_hour <= 23 AND
  comm_end_hour >= 0 AND comm_end_hour <= 23 AND
  safeguarding_alert_hour >= 0 AND safeguarding_alert_hour <= 23
);

ALTER TABLE consent_records ADD CONSTRAINT chk_consent_status_consistency CHECK (
  (status = 'GRANTED' AND revoked_at IS NULL) OR
  (status = 'REVOKED' AND revoked_at IS NOT NULL)
);

ALTER TABLE audit_events ADD CONSTRAINT chk_audit_actor_consistency CHECK (
  (actor_id IS NULL AND actor_type = 'SYSTEM') OR
  (actor_id IS NOT NULL AND actor_type IN ('STAFF', 'PARENT'))
);

ALTER TABLE messages ADD CONSTRAINT chk_message_delete_after CHECK (delete_after IS NULL OR delete_after > sent_at);
ALTER TABLE media ADD CONSTRAINT chk_media_delete_after CHECK (delete_after IS NULL OR delete_after > created_at);

-- Consistency triggers
CREATE OR REPLACE FUNCTION public.validate_activity_log_school()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public
AS $$
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

CREATE OR REPLACE FUNCTION public.validate_media_tag_consent()
RETURNS trigger LANGUAGE plpgsql
SET search_path = public
AS $$
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

-- RLS: enable + school isolation on all tenant tables
DO $$
DECLARE tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'schools','subscriptions','school_memberships',
    'classrooms','classroom_staff',
    'children','parent_child_links',
    'consent_records','daily_reports','activity_log_entries',
    'media','media_child_tags',
    'messages','message_receipts',
    'attendance_records','audit_events',
    'device_push_tokens','notification_preferences'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END;
$$;

CREATE POLICY school_isolation ON schools USING (id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON subscriptions USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON school_memberships USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON classrooms USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON classroom_staff USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON children USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON parent_child_links USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON consent_records USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON daily_reports USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON activity_log_entries USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON media USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON media_child_tags USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON messages USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON message_receipts USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON attendance_records USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY school_isolation ON audit_events USING (school_id = (auth.jwt() ->> 'school_id')::uuid);
CREATE POLICY user_isolation ON device_push_tokens USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY user_isolation ON notification_preferences USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Block public access to Prisma internals
ALTER TABLE _prisma_migrations ENABLE ROW LEVEL SECURITY;

-- users RLS (enable + self-access policy)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_self_access ON users USING (auth_id = auth.uid());
