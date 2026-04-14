# Architecture Diagram
**Last Updated**: 2026-04-14

```mermaid
flowchart TD
    subgraph clients["Client Layer"]
        TA["Teacher App\nReact Native + Expo + WatermelonDB"]
        PA["Parent App\nReact Native + Expo + WatermelonDB"]
        WA["Web App\nNext.js"]
    end

    subgraph supa_auth["Supabase Auth — EU Frankfurt"]
        AUTH["Email / Password · Google · Apple\nInvite flow · Password reset\nJWT issued with: user_id · school_id · role"]
    end

    subgraph flyio["Fly.io — Frankfurt"]
        API["API Server\nNode.js 22 + Fastify + TypeScript\nREST + Socket.IO"]
        WORKERS["BullMQ Workers\nPush · Video · Retention · Safeguarding · Audit"]
        REDIS["Upstash Redis\nSocket.IO adapter · BullMQ queues · Rate limits"]
        API <-->|"enqueue / process"| WORKERS
        API --- REDIS
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

    TA & PA & WA -->|"① login\nemail/password · Google · Apple"| AUTH
    AUTH -->|"② JWT returned to client"| TA & PA & WA
    TA & PA & WA -->|"③ REST + WebSocket\nJWT on every request"| API
    TA -->|"④ direct upload\nvia pre-signed URL"| TIGRIS
    PA & WA -.->|"download via\n15-min signed URL"| TIGRIS
    API -->|"⑤ Prisma queries\nRLS enforced via JWT claims"| APP_DB
    WORKERS -->|"⑥"| FCM & BREVO & STRIPE
```

## Flow Reference

| # | Description |
|---|---|
| ① | Client authenticates directly with Supabase Auth — the API server never sees the password |
| ② | Supabase Auth returns a JWT with `school_id` and `role` injected via a custom PostgreSQL hook |
| ③ | All API and WebSocket calls go to Fly.io with the JWT in the `Authorization` header |
| ④ | Media uploads go directly from the client to Tigris via a pre-signed URL — the API server never proxies the file |
| ⑤ | API server queries Supabase via Prisma; RLS policies read `school_id` + `role` from the JWT, blocking cross-tenant access at DB level |
| ⑥ | BullMQ workers dispatch push notifications (FCM), emails (Brevo), and payment events (Stripe) |
