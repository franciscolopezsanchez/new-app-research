# Feature List — V1 and Differentiator Candidates
**Product Area**: Core Platform
**Last Updated**: 2026-03-20
**Version**: 1.0
**Status**: Draft — confirmed V1 scope, differentiator features pending competitive validation

---

## How to Read This Document

- **Must Have**: V1 is not shippable without this.
- **Should Have**: Significantly improves V1; ship in V1 if capacity allows, otherwise V1.1 within 6 weeks.
- **Nice to Have**: Real user value but not blocking adoption. Schedule in a later cycle.
- Complexity estimates assume a small team (1–2 mobile engineers, 1 backend engineer, 1 designer).

See `user-personas.md` for persona context (Carmen = director, Laura = teacher, Sofia/Alejandro = parents).

---

## V1 Confirmed Feature Set

### Feature 1 — Direct Messaging (Teacher ↔ Parent, Director → All)

**Priority**: Must Have

**Problem it solves**: Teachers and directors currently use personal WhatsApp numbers. This creates boundary violations, GDPR exposure, and a communication channel the school cannot audit.

**User Stories**:

| # | Story | Acceptance Criteria |
|---|---|---|
| 1.1 | As Laura, I want to send a message to an individual parent without using my personal phone number. | Delivered within 5 seconds. Sender shows as teacher name + school. |
| 1.2 | As Laura, I want to send a broadcast message to all families in my classroom without creating a group chat where parents reply-all. | All linked parents receive the message. Parents cannot reply to the broadcast thread. |
| 1.3 | As Sofia, I want to receive a push notification when I get a message. | Notification within 10 seconds. Tapping opens the specific thread. |
| 1.4 | As Carmen, I want to send school-wide announcements to all families. | Director can target: single class, multiple classes, or whole school. Message logged with timestamp and read receipts. |
| 1.5 | As Carmen, I want read receipts on broadcast messages to know which parents have not opened a notice. | Read/unread status visible per recipient on sent messages. |
| 1.6 | As Laura, I want defined communication hours (e.g., 7am–7pm) enforced by the app so parents cannot expect replies outside those hours. | App shows "outside communication hours" state to parents during off-hours. Incoming messages queued until next open window. |

**Complexity**: Medium. Standard messaging infrastructure. The broadcast-with-no-reply-all behavior is the key UX challenge. Read receipts add minor backend work.

**GDPR Note**: All messages must be stored server-side in the school's account. Message retention policy must be configurable by the director.

---

### Feature 2 — Daily Activity Reports / Activity Logs

**Priority**: Must Have

**Problem it solves**: Teachers produce no structured daily record, or produce one on paper. Parents have no visibility into their child's day between drop-off and pickup.

**User Stories**:

| # | Story | Acceptance Criteria |
|---|---|---|
| 2.1 | As Laura, I want to log daily activities for my whole class at once so I do not have to write the same thing 14 times. | Single class-level activity log auto-distributes to all linked families. Completable in under 2 minutes. |
| 2.2 | As Laura, I want to add child-specific notes to a daily report when relevant. | Optional per-child note field. Blank by default, visible only to that child's family if filled in. |
| 2.3 | As Laura, I want to log meal information (ate well / ate some / did not eat) for each child. | Quick-select meal status per child (3 options maximum — no free text required). |
| 2.4 | As Laura, I want to log nap/rest information for each child. | Nap start/end time or simple status (slept well / restless / did not sleep) per child. |
| 2.5 | As Sofia, I want to receive a push notification once the daily report is published. | Notification sent when teacher marks report published. Includes child's name and class activity preview. |
| 2.6 | As Sofia, I want to view a history of daily reports for the past 90 days. | Report archive accessible in parent app, filterable by date. Minimum 90 days of history. |
| 2.7 | As Carmen, I want to see which teachers have submitted daily reports and which have not. | Director dashboard shows report status per class: submitted / not yet submitted. Visible by default at 3pm. |

**Complexity**: Medium-High. Class-level report with individual child overrides is the core data model challenge. Must be fast — if it takes more than 3 minutes, Laura will stop doing it. Use template-driven input (activity tags, mood indicators, meal pickers) rather than free-text-only.

---

### Feature 3 — Photo and Video Sharing

**Priority**: Must Have

**Problem it solves**: Schools currently share photos via WhatsApp groups, which creates GDPR violations (child images distributed without individual consent) and no organized archive.

**User Stories**:

| # | Story | Acceptance Criteria |
|---|---|---|
| 3.1 | As Laura, I want to upload photos from my phone to a child's daily report. | Upload from camera roll or in-app camera. No limit on number of photos per report. Under 5 seconds per photo on 4G (client-side compression applied before upload). |
| 3.2 | As Laura, I want to tag which children appear in each photo so photos are only visible to tagged families. | Mandatory tagging flow before publish. Photo not visible to untagged families. This is the GDPR-compliant replacement for group WhatsApp sharing. |
| 3.3 | As Laura, I want to upload videos from my phone. | Video upload supported, no duration limit. Max 500MB per file. Client-side compression applied before upload. Auto-generated thumbnail shown in feed. |
| 3.4 | As Sofia, I want to view and save photos and videos of my child to my camera roll. | Download button on each photo and video. Original quality retained. Watermarking optional (director preference). |
| 3.5 | As Sofia, I want a push notification when a new photo of my child is posted. | Notification within 30 seconds of publish. Thumbnail shown if OS permissions allow. |
| 3.6 | As Carmen, I want to confirm parents have given photo consent before their child's images are shared. | Consent status tracked per child per family. Teacher cannot tag a child if consent is not recorded. Consent collected digitally during parent onboarding. |

**Complexity**: High. Photo tagging with per-child visibility rules is non-trivial. GDPR consent model needs legal review — do not ship photo sharing without it.

**Storage and cost note**: No per-report media limits. Storage cost is negligible at target scale (~2 GB/school/month on Cloudflare R2, no egress fees). Limits are UX-driven only (500 MB/file) to prevent unacceptably long uploads on mobile. Media never passes through the app server — teachers upload directly to R2 via pre-signed URLs. Thumbnails served via R2 image transformations. See `architecture.md` for implementation detail.

**Note on external messaging**: Do NOT relay photos or videos to external channels (WhatsApp, Telegram, email). Media stays in-platform; external notifications send text + deep link only. Sending child images to third-party servers undermines the GDPR compliance that is our core sales argument.

---

### Feature 4 — Attendance Tracking

**Priority**: Must Have

**Problem it solves**: Most preschools track attendance on paper registers. No searchable record, impossible to identify absence patterns, manual aggregation for reporting.

**User Stories**:

| # | Story | Acceptance Criteria |
|---|---|---|
| 4.1 | As Laura, I want to mark each child as present, absent, or late at the start of each day. | Attendance screen shows all children. Mark all present by default with one tap, then mark exceptions. Under 60 seconds for a class of 14. |
| 4.2 | As Laura, I want to record the reason for absence if a parent has notified me. | Optional reason field (free text or selectable: sick / family / unknown) when marking absent. |
| 4.3 | As Sofia, I want to notify the school that my child will be absent today. | Parent can submit absence notification from app before school starts. Teacher sees it flagged in the attendance screen. |
| 4.4 | As Carmen, I want to view an attendance summary for my school. | Director dashboard: attendance rate per class per week and month. Export to CSV or PDF. |
| 4.5 | As Carmen, I want to be alerted when a child is marked absent without prior parent notification. | Configurable alert: if child is absent and no parent notification exists by a set time (e.g., 9:30am), notify Carmen or designated contact. |

**Complexity**: Low-Medium. The safeguarding alert (4.5) is the most important and often overlooked — it is a compliance, safety, and sales feature simultaneously.

---

## V1 Feature Summary

| Feature | Priority | Complexity | Primary User | Key Risk |
|---|---|---|---|---|
| Direct Messaging | Must Have | Medium | Teacher, Director | Communication hours UX; GDPR message storage |
| Daily Activity Reports | Must Have | Medium-High | Teacher | Speed of input on mobile; adoption drop-off if too slow |
| Photo / Video Sharing | Must Have | High | Teacher (upload), Parent (consume) | GDPR consent model; video storage costs |
| Attendance Tracking | Must Have | Low-Medium | Teacher, Director | Safeguarding alert logic; regulatory export format |

---

## V1 Non-Goals (Explicitly Deferred)

| Request | Reason for Deferral | Revisit Condition |
|---|---|---|
| Parent-to-teacher two-way free messaging | High moderation complexity; teacher boundary risk; validate whether read-only daily reports reduce parent message volume first | If post-launch data shows daily reports do not reduce parent anxiety signal |
| Billing and payment collection | Separate product decision required | If director interviews show payment friction as top-3 pain point |
| Child developmental progress tracking (portfolios) | High complexity; requires pedagogical framework alignment | After V1 engagement metrics validate daily report adoption |
| Calendar and event management | Useful but not core to daily loop | Q2 after V1 metrics reviewed |
| Multi-language support (beyond Spanish) | No validated demand for additional languages in V1 target schools | When >10% of enrolled families request it or expanding beyond Spain |

---

## Differentiator Feature Candidates (Post-V1)

### Differentiator 1 — GDPR-Native Consent Management

**Hypothesis**: Spanish preschools are broadly non-compliant with GDPR regarding child photos, and most are unaware of their exposure. A product that makes compliance effortless — with documentation directors can show inspectors — is a purchasing argument, not just a feature.

**What it looks like**:
- Digital consent collection during parent onboarding (photo, communication, data retention)
- Consent audit trail exportable as PDF
- Automatic content visibility rules driven by consent status
- Data retention settings: auto-delete photos and messages after a configurable period

**Why it differentiates**: Competitors (especially ClassDojo) handle GDPR with generic privacy policies, not product-level compliance features. Sales argument: "ClassDojo puts your school at legal risk. We don't."

**Validation needed**: Interview 5 directors on GDPR awareness and whether compliance tooling appears in their purchasing decision.

**Complexity**: Medium. Mostly data model and settings UI. Legal review required.

**Priority**: Should Have for V1.1 — the consent collection part must exist before photo sharing ships regardless.

---

### Differentiator 2 — Child Memory Timeline (End-of-Year Export)

**Hypothesis**: Parents of 0–6 year olds have an emotional attachment to documenting their child's early years. A product that turns daily reports and photos into an exportable memory timeline creates habit and switching cost that pure communication tools do not have.

**What it looks like**:
- Chronological visual feed of all photos, activity highlights, and milestones
- End-of-year "memory book" export — printable PDF or shareable digital album
- Milestone tagging: "first painting," "started walking," etc.

**Why it differentiates**: No competitor in the Spanish market offers this as a polished, export-quality feature. Turns the app from a communication tool into something parents emotionally invest in — and are unlikely to abandon even if the school switches platforms.

**Validation needed**: Ask parents: "If the school stopped using the app next September, would you want to keep access to your child's history?" If yes for >60%, this is a retention feature.

**Complexity**: Medium. Data already exists. Timeline view and export are primarily a design and frontend challenge.

**Priority**: Nice to Have for V1.1; Should Have for V2.

---

### Differentiator 3 — Teacher Wellbeing and Boundary Enforcement

**Hypothesis**: Teacher burnout and after-hours communication pressure are well-documented problems in Spanish early education. A product that actively protects teachers' personal time creates loyalty among teaching staff.

**What it looks like**:
- Communication hours enforced at platform level (not just a setting parents can ignore)
- Weekly communication load summary for teachers
- Director dashboard showing teacher communication patterns
- "Out of office" status with automatic redirect to director or substitute

**Why it differentiates**: Reframes the product pitch from "parent engagement tool" to "teacher support tool." Carmen buys the product, but Laura's daily adoption determines whether it stays in the budget.

**Validation needed**: Ask teachers whether after-hours messaging is a top-3 pain point. Ask directors whether teacher retention is a concern.

**Complexity**: Low-Medium. Mostly logic rules on top of existing messaging infrastructure.

**Priority**: Should Have for V1.1.

---

### Differentiator 4 — Multilingual Parent Interface

**Hypothesis**: Spain has a significant population of immigrant families whose primary language is not Spanish (Arabic, Romanian, Chinese, English, Ukrainian). Auto-translation removes a real barrier to family engagement.

**What it looks like**:
- Parent app available in Spanish, English, Arabic, Romanian, Chinese (Simplified) at minimum
- Teacher writes in Spanish; app offers parent auto-translated view
- Language preference set during parent onboarding

**Why it differentiates**: No direct competitor in the Spanish preschool market offers this. Meaningful for schools in Barcelona, Madrid, and Valencia with diverse family populations.

**Complexity**: Low (UI localization) to Medium (translation API integration + RTL layout for Arabic). Can be phased: English first, then Arabic.

**Priority**: Nice to Have for V1.1; Should Have for V2 if urban school traction confirms the hypothesis.

---

### Differentiator 5 — School-Level Analytics for Directors

**Hypothesis**: Directors make decisions (staffing, marketing, enrollment) with very little data. A product that surfaces engagement metrics gives directors a business intelligence layer they do not have today.

**What it looks like**:
- Enrollment dashboard: capacity vs. enrollment per class, re-enrollment status
- Parent engagement score per family: opens, notifications enabled, last login
- Communication completion rate: which teachers submit daily reports consistently
- Optional in-app satisfaction pulse once per term

**Why it differentiates**: ClassDojo and Tapestry are teacher-and-parent tools. Neither offers a director-level analytics layer. Makes the ROI of the subscription concrete and visible.

**Complexity**: Medium-High for the dashboard. **Start tracking engagement events in V1 even if the dashboard ships in V2 — this is a prerequisite.**

**Priority**: Instrument in V1 (no additional complexity). Dashboard UI in V2.

---

## Competitive Context

The primary competitor is not another app — it is **WhatsApp + paper**. Every feature decision should be evaluated against: "Is this enough better than WhatsApp + paper to justify the behavior change and the subscription cost?"

| Competitor | Key Gap vs Our Target |
|---|---|
| ClassDojo | Free but irrelevant for 0–3; GDPR generic; US-hosted |
| Brightwheel | Best-in-class 0–5 ops but English-only and LOPDGDD non-compliant |
| Famly | Best European 0–6 product but zero Spanish presence |
| Educa | Spanish but dated UX, no care-focused features for 0–6 |
| Konveria | Spanish compliance but no media sharing, no 0–3 depth |
| WhatsApp | Zero switching cost, maximum familiarity — our hardest competitor |
