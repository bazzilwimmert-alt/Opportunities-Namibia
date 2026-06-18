const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const config = require('./config');
const { revokeExpiredSubscriptions } = require('./services/subscription');

const publicRoutes = require('./routes/public');
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profiles');
const subscriptionRoutes = require('./routes/subscription');
const catalogRoutes = require('./routes/catalog');
const adminRoutes = require('./routes/admin');
const webhookRoutes = require('./routes/webhooks');

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: config.corsOrigins.includes('*') ? true : config.corsOrigins,
  })
);
app.use(morgan('dev'));

// PayToday webhooks need the raw body for signature verification.
app.use('/api/webhooks', express.raw({ type: '*/*' }), webhookRoutes);

app.use(express.json());

const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 50 });

app.get('/api/health', (req, res) => res.json({ ok: true, service: 'bax-backend' }));

app.use('/api/public', publicRoutes);
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/profiles', profileRoutes);
app.use('/api/subscription', subscriptionRoutes);
app.use('/api/catalog', catalogRoutes);
app.use('/api/admin', adminRoutes);

app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

// Periodically revoke streaming rights for subscriptions whose paid period has
// lapsed (runs hourly; also runnable as a cron via npm run billing:run).
const BILLING_INTERVAL_MS = 60 * 60 * 1000;
setInterval(() => {
  revokeExpiredSubscriptions()
    .then((n) => {
      if (n > 0) console.log(`[billing] revoked ${n} expired subscription(s)`);
    })
    .catch((e) => console.error('[billing] error', e));
}, BILLING_INTERVAL_MS);

app.listen(config.port, () => {
  console.log(`Bax backend running on http://localhost:${config.port}`);
});

module.exports = app;
