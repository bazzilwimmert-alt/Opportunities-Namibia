const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const config = require('./config');
const { expireMemberships, sendExpiryReminders } = require('./services/membership');
const { ingestAll } = require('./services/ingest');

const publicRoutes = require('./routes/public');
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profiles');
const membershipRoutes = require('./routes/membership');
const jobRoutes = require('./routes/jobs');
const notificationRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/admin');

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: config.corsOrigins.includes('*') ? true : config.corsOrigins,
  })
);
app.use(morgan('dev'));
app.use(express.json());

const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 50 });

app.get('/api/health', (req, res) =>
  res.json({ ok: true, service: 'opportunities-namibia-backend' }));

app.use('/api/public', publicRoutes);
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/profiles', profileRoutes);
app.use('/api/membership', membershipRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);

app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

// Hourly: expire memberships whose paid 6-month period has lapsed (revoking
// access until the next payment) and send "expiring soon" reminders.
const runMembershipMaintenance = () =>
  Promise.all([expireMemberships(), sendExpiryReminders()])
    .then(([expired, reminded]) => {
      if (expired > 0) console.log(`[membership] expired ${expired} membership(s)`);
      if (reminded > 0) console.log(`[membership] sent ${reminded} expiry reminder(s)`);
    })
    .catch((e) => console.error('[membership] error', e));
setTimeout(runMembershipMaintenance, 5 * 1000);
setInterval(runMembershipMaintenance, 60 * 60 * 1000);

// Periodically pull new vacancies from configured online sources.
if (config.ingestion.enabled) {
  const runIngest = () =>
    ingestAll()
      .then((r) => console.log(`[ingest] ${r.created} new job(s) from ${r.sources} source(s)`))
      .catch((e) => console.error('[ingest] error', e));
  setTimeout(runIngest, 10 * 1000);
  setInterval(runIngest, config.ingestion.intervalMinutes * 60 * 1000);
}

app.listen(config.port, () => {
  console.log(`Opportunities Namibia backend running on http://localhost:${config.port}`);
});

module.exports = app;
