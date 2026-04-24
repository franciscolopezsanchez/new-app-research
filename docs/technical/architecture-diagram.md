# Architecture Diagram
**Last Updated**: 2026-04-25

```mermaid
flowchart TD
    subgraph clients["Client Layer"]
        TA["Teacher App\nExpo WebView shell"]
        PA["Parent App\nExpo WebView shell"]
        WA["Web Browser"]
    end

    subgraph flyio["Fly.io — Frankfurt"]
        NEXT["Next.js 15\nApp Router UI + Route Handlers\nBetter Auth /api/auth/*\nSSE /api/v1/stream"]
        WORKERS["BullMQ Worker\n(separate process)\nPush · Video · Retention · Erasure · Safeguarding"]
        REDIS["Upstash Redis\nBullMQ queues · Rate limits"]
        PG["Fly Postgres\nauth + app data (single DB)\nRow-Level Security per tenant"]
        NEXT <-->|"enqueue / process"| WORKERS
        NEXT & WORKERS --- REDIS
        NEXT -->|"⑤ Prisma queries\nSET LOCAL app.school_id\nRLS blocks cross-tenant access"| PG
    end

    TIGRIS["Tigris — EU Frankfurt\nPhoto + Video Storage\nPre-signed URLs · Zero public access"]

    subgraph external["External Services"]
        FCM["FCM / APNs\nPush notifications"]
        BREVO["Brevo\nTransactional email"]
        STRIPE["Stripe SEPA\nPayments"]
    end

    TA & PA & WA -->|"① login\nemail/password · Google · Apple"| NEXT
    NEXT -->|"② JWT cookie\nHttpOnly · Secure · SameSite=Strict"| TA & PA & WA
    TA & PA & WA -->|"③ REST calls\ncookie on every request"| NEXT
    TA & PA & WA -->|"④ SSE connection\nserver-push events"| NEXT
    TA -->|"⑥ direct upload\nvia pre-signed URL"| TIGRIS
    PA & WA -.->|"download via\n15-min signed URL"| TIGRIS
    WORKERS -->|"⑦"| FCM & BREVO & STRIPE
```

## Flow Reference

| # | Description |
|---|---|
| ① | Client authenticates via Better Auth, mounted as a Next.js Route Handler at `/api/auth/*` — email/password, Google, or Apple OAuth |
| ② | Better Auth sets a signed JWT in an HttpOnly cookie; the WebView cookie jar handles it automatically — no token storage code needed in the Expo shell |
| ③ | All REST API calls go to Next.js Route Handlers (`/api/v1/*`) with the JWT cookie on every request; `requireAuth()` validates the session and sets the RLS tenant context |
| ④ | While the user has the app open, a persistent SSE connection (`/api/v1/stream`) delivers server-push events: `message.new`, `report.published`, `media.ready` |
| ⑤ | Next.js queries Fly Postgres via Prisma; `requireAuth()` runs `SET LOCAL app.school_id = <uuid>` before every request, and RLS policies block any cross-tenant row access at the DB level |
| ⑥ | Media uploads go directly from the client to Tigris via a short-lived pre-signed URL — Next.js never proxies the file bytes |
| ⑦ | BullMQ workers (running as a separate process on the same Fly machine) dispatch push notifications (FCM), transactional emails (Brevo), and payment events (Stripe) |
