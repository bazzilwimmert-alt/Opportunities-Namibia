# Opportunities Namibia — Namibian Jobs Board

Opportunities Namibia is a cross-platform jobs board for **every Namibian
vacancy**, skilled and unskilled. Users register, pay a membership of
**N$200 (NAD) every 6 months** by mobile payment to the operator's phone
number, and — once an admin confirms the payment — unlock full access to browse,
search and apply for jobs. Access lasts 6 months and is automatically
**revoked** when it lapses, until a new payment is confirmed.

> **Sourcing note:** Vacancies can be added manually by an admin and pulled
> automatically from configured online sources. The ingestion layer ships a
> working **RSS/Atom** adapter. **LinkedIn cannot be scraped** (it violates
> LinkedIn's Terms of Service and is actively blocked); the LinkedIn adapter is
> a documented stub that requires official LinkedIn Jobs API / partner access to
> enable.

> **Screenshot note:** Screenshots are hard-blocked on **Android**
> (`FLAG_SECURE`). On Web, Windows and iOS the OS does not let an app prevent
> screenshots, so all listings carry a per-account **identity watermark** (any
> leaked image is traceable) plus a clear prohibition notice. Members accept a
> no-screenshot term at signup.

## Architecture

| Part | Stack | Location |
|------|-------|----------|
| Client | Flutter (Android, iOS, Windows, Web) | [`app/`](app/) |
| Backend API | Node.js, Express, Prisma, SQLite | [`backend/`](backend/) |
| Membership | Manual mobile payment + admin confirmation | [`backend/src/services/membership.js`](backend/src/services/membership.js) |
| Ingestion | Pluggable source adapters (RSS working) | [`backend/src/services/ingest.js`](backend/src/services/ingest.js) |

The admin panel is a role-gated section inside the same Flutter app (visible
only to `ADMIN` users), so admins can edit the entire platform online.

## Features

- Email/password **signup & login** with JWT auth (no age gate / guardians)
- **N$200 / 6 months** membership paid to a phone number, confirmed by an admin
- **Access-gated vacancies** — non-members see locked previews; members see full
  details and how to apply. Access auto-expires after 6 months (hourly job)
- **Search & filter** by keyword, category, skill level (skilled/unskilled),
  type and location
- **Up to 2 profiles** per account (job-seeker headline)
- **Auto-sourcing** of vacancies from configured RSS sources + admin "Fetch now"
  (seeded with Careerjet Namibia + a remote-jobs feed; LinkedIn is a disabled stub)
- **Membership-expiry notifications** — in-app (with unread badge) and optional
  email: members are reminded before access lapses, told when it expires, and
  notified when a payment is confirmed or rejected
- **Identity watermark** + Android screenshot blocking
- **Admin console**: dashboard stats, confirm/reject payments, manage users
  (grant/revoke access, roles, suspend), full vacancy CRUD, manage ingestion
  sources, and live-editable platform settings (price phone, branding, etc.)

## Running locally

### 1. Backend

```bash
cd backend
cp .env.example .env
npm install
npx prisma generate
npx prisma db push
npm run seed      # creates admin + sample Namibian vacancies
npm start         # http://localhost:4000
```

Seeded admin: `admin@opportunities.na` / `Admin123!`

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

### 3. Android APK

```bash
cd app
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk

# For a real device, bake in your hosted (HTTPS) backend URL:
flutter build apk --release --dart-define=BAX_API_BASE=https://api.yourhost.com
```

Screenshots and screen recording are blocked on Android via `FLAG_SECURE`
(see [`MainActivity.kt`](app/android/app/src/main/kotlin/tv/bax/bax/MainActivity.kt));
an OS screen capture of the app produces a blank/black image.

## Going to production

1. **Database**: switch the Prisma `datasource` from SQLite to PostgreSQL.
2. **Payments**: members pay `PAYMENT_PHONE` by mobile transfer; an admin
   confirms each claim in the admin console to grant a 6-month period.
3. **Ingestion**: add RSS/Atom sources in the admin console. To enable LinkedIn,
   supply official LinkedIn Jobs API credentials and implement the documented
   stub in `backend/src/services/ingest.js`.
4. **Maintenance job**: schedule `npm run maintenance:run` (cron) to expire
   lapsed memberships, send expiry reminders, and run ingestion (also runs
   in-process hourly).
5. **Email notifications** (optional): set `SMTP_HOST`/`SMTP_PORT`/`SMTP_USER`/
   `SMTP_PASS`/`MAIL_FROM` in `.env`. Without SMTP, notifications are still
   created in-app and logged to the server console. `EXPIRY_REMINDER_DAYS`
   controls how many days before expiry the reminder is sent (default 7).

## API overview

- `POST /api/auth/signup`, `POST /api/auth/login`, `GET /api/auth/me`
- `GET /api/public/config`
- `GET /api/jobs`, `GET /api/jobs/categories`, `GET /api/jobs/:id`
- `GET /api/membership`, `POST /api/membership/pay`, `GET /api/membership/payments`
- `GET /api/notifications`, `POST /api/notifications/:id/read`, `POST /api/notifications/read-all`
- `GET/POST/PATCH/DELETE /api/profiles`
- `GET /api/admin/stats|users`, `POST /api/admin/users/:id/access`
- `GET /api/admin/payments`, `POST /api/admin/payments/:id/confirm|reject`
- CRUD `/api/admin/jobs`, `/api/admin/sources`, `POST /api/admin/sources/:id/fetch`,
  `POST /api/admin/ingest`, `PUT /api/admin/settings/:key`
