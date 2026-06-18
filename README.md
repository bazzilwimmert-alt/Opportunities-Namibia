# Bax — Live Sports Streaming

Bax is a cross-platform live sports streaming platform. Users sign up, pay a
monthly subscription of **N$200 (NAD)** via **PayToday**, and stream channels
across every sport — soccer, basketball, Formula 1, tennis, swimming, cricket,
rugby, American football and more. If a monthly payment is missed, streaming
rights are automatically **revoked** until payment is made again.

> **Content / legal note:** This repository ships the full streaming *platform*
> (accounts, billing, entitlements, profiles, admin). It uses legal, public
> **sample videos** as placeholder content. Live sports feeds are owned by
> rights holders — connect your own CRAN-licensed streams via the admin panel
> (each channel accepts an HLS/DASH/MP4 URL). Obtaining broadcast/streaming
> rights and CRAN authorisation is the operator's responsibility.

## Architecture

| Part | Stack | Location |
|------|-------|----------|
| Client | Flutter (Android, iOS, Windows, Web) | [`app/`](app/) |
| Backend API | Node.js, Express, Prisma, SQLite | [`backend/`](backend/) |
| Payments | PayToday adapter (sandbox + live hook) | [`backend/src/services/payToday.js`](backend/src/services/payToday.js) |

The admin panel is a role-gated section inside the same Flutter app (visible
only to `ADMIN` users), so admins can edit the entire platform online.

## Features

- Email/password **signup & login** with JWT auth
- **Age gate (18+)** and Terms/Privacy consent at signup (compliance scaffolding)
- **N$200/month** subscription via **PayToday** (sandbox now, live adapter ready)
- **Payment-gated playback** — stream URLs are only issued to paid, active users;
  rights are auto-revoked when the paid period lapses (hourly job + on-demand)
- **Up to 2 profiles** per account
- Sport channels with a built-in **video player**
- **Admin console**: dashboard stats, manage users (grant/revoke access, roles,
  suspend), full CRUD on sports & channels, and live-editable platform settings

## Running locally

### 1. Backend

```bash
cd backend
cp .env.example .env
npm install
npx prisma generate
npx prisma db push
npm run seed      # creates admin + sports/channels
npm start         # http://localhost:4000
```

Seeded admin: `admin@bax.tv` / `Admin123!`

### 2. Flutter app

```bash
cd app
flutter pub get

# Web
flutter run -d chrome

# Android emulator (API base auto-resolves to 10.0.2.2:4000)
flutter run -d emulator-5554

# Point at a custom backend
flutter run --dart-define=BAX_API_BASE=https://api.yourhost.com
```

## Going to production

1. **PayToday**: set `PAYTODAY_MODE=live` and provide `PAYTODAY_MERCHANT_ID` /
   `PAYTODAY_API_KEY` / `PAYTODAY_WEBHOOK_SECRET`. The REST integration point is
   marked in `backend/src/services/payToday.js`; point the PayToday webhook at
   `POST /api/webhooks/paytoday`.
2. **Database**: switch the Prisma `datasource` from SQLite to PostgreSQL.
3. **Streams**: replace sample `streamUrl`s with your licensed HLS/DASH feeds via
   the admin panel.
4. **Billing job**: schedule `npm run billing:run` (cron) to revoke lapsed
   subscriptions (also runs hourly in-process).

## API overview

- `POST /api/auth/signup`, `POST /api/auth/login`, `GET /api/auth/me`
- `GET /api/public/config`
- `GET /api/catalog/sports`, `GET /api/catalog/channels/:id/play`
- `GET /api/subscription`, `POST /api/subscription/checkout`,
  `POST /api/subscription/sandbox/confirm`, `POST /api/subscription/cancel`
- `GET/POST/PATCH/DELETE /api/profiles`
- `GET /api/admin/stats|users`, `POST /api/admin/users/:id/subscription`,
  CRUD `/api/admin/sports`, `/api/admin/channels`, `/api/admin/settings/:key`
- `POST /api/webhooks/paytoday`
