# Architecture Diagram
**Last Updated**: 2026-04-17

```mermaid
flowchart TD
    subgraph clients["Client Layer"]
        MA["Mobile App\nReact Native WebView (Expo)\nPush notifications via Expo"]
        WB["Web Browser"]
    end

    subgraph supa_auth["Supabase Auth — EU Frankfurt"]
        AUTH["Email / Password · Google · Apple\nInvite flow · Password reset\nJWT issued with: user_id · school_id · role"]
    end

    subgraph flyio["Fly.io — Frankfurt"]
        NEXT["Next.js App (web process)\nServer Components · Route Handlers\nServer Actions · Next.js Middleware\nSocket.IO (custom server layer)"]
        WORKERS["BullMQ Workers (worker process)\nPush · Video · Retention · Safeguarding · Audit"]
        REDIS["Upstash Redis\nSocket.IO adapter · BullMQ queues · Rate limits"]
        NEXT <-->|"enqueue / process"| WORKERS
        NEXT --- REDIS
        WORKERS --- REDIS
    end

    subgraph supa_db["Supabase PostgreSQL — EU Frankfurt"]
        AUTH_USERS["auth.users\nmanaged by Supabase Auth"]
        APP_DB["public schema\nusers · classrooms · children\ndaily_reports · media · messages\nattendance · consent · audit"]
        AUTH_USERS -->|"INSERT trigger\nauto-creates public.users row"| APP_DB
    end

    TIGRIS["Tigris — EU Frankfurt\nPhoto + Video Storage\nPre-signed upload & download URLs\nZero public access"]

    subgraph external["External Services"]
        FCM["FCM / APNs\nPush notifications"]
        BREVO["Brevo\nTransactional email"]
        STRIPE["Stripe SEPA\nPayments"]
    end

    MA & WB -->|"① login\nemail/password · Google · Apple"| AUTH
    AUTH -->|"② JWT returned to client"| MA & WB
    MA & WB -->|"③ HTTPS + WebSocket\nJWT on every request"| NEXT
    MA & WB -->|"④ direct upload\nvia pre-signed URL"| TIGRIS
    MA & WB -.->|"download via\n15-min signed URL"| TIGRIS
    NEXT -->|"⑤ Prisma queries\nRLS enforced via JWT claims"| APP_DB
    WORKERS -->|"⑥"| FCM & BREVO & STRIPE
```

## Flow Reference

| # | Description |
|---|---|
| ① | Client authenticates directly with Supabase Auth — the Next.js app never sees the password |
| ② | Supabase Auth returns a JWT with `school_id` and `role` injected via a custom PostgreSQL hook |
| ③ | All requests (page loads, Server Actions, Socket.IO) go to the Next.js app on Fly.io with the JWT; Next.js Middleware sets the RLS session variable before any DB query |
| ④ | Media uploads go directly from the client to Tigris via a pre-signed URL — Next.js never proxies the file |
| ⑤ | Server Components and Server Actions query Supabase via Prisma; RLS policies read `school_id` + `role` from the session config, blocking cross-tenant access at DB level |
| ⑥ | BullMQ workers (separate Fly.io process) dispatch push notifications (FCM), emails (Brevo), and payment events (Stripe) |

## Key Differences from Previous Architecture

| Before | After |
|--------|-------|
| Separate Fastify API server | Unified Next.js app (Server Components + Route Handlers + Server Actions) |
| React Native full native app with WatermelonDB | React Native WebView wrapper — no native data layer |
| Offline sync via native SQLite + pull/push protocol | Offline via PWA service worker + IndexedDB (Dexie.js) |
| Mobile and web as separate API consumers | Mobile loads the web app in a WebView — single product surface |
