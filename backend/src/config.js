require('dotenv').config();

const config = {
  port: parseInt(process.env.PORT || '4000', 10),
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  membership: {
    priceCents: parseInt(process.env.MEMBERSHIP_PRICE_CENTS || '20000', 10), // N$200
    currency: process.env.MEMBERSHIP_CURRENCY || 'NAD',
    periodMonths: parseInt(process.env.MEMBERSHIP_PERIOD_MONTHS || '6', 10),
  },
  // Manual mobile payment: members pay this number, an admin then confirms.
  payment: {
    phone: process.env.PAYMENT_PHONE || '+264814680324',
    accountName: process.env.PAYMENT_ACCOUNT_NAME || 'Opportunities Namibia',
  },
  ingestion: {
    enabled: (process.env.INGESTION_ENABLED || 'true') === 'true',
    intervalMinutes: parseInt(process.env.INGESTION_INTERVAL_MINUTES || '360', 10),
  },
  notifications: {
    // Send an "expiring soon" reminder this many days before access lapses.
    reminderDaysBefore: parseInt(process.env.EXPIRY_REMINDER_DAYS || '7', 10),
    // Email is optional: if SMTP isn't configured, notifications are still
    // created in-app and logged to the server console.
    fromEmail: process.env.MAIL_FROM || 'no-reply@opportunities.na',
    smtp: {
      host: process.env.SMTP_HOST || '',
      port: parseInt(process.env.SMTP_PORT || '587', 10),
      secure: (process.env.SMTP_SECURE || 'false') === 'true',
      user: process.env.SMTP_USER || '',
      pass: process.env.SMTP_PASS || '',
    },
  },
  admin: {
    email: process.env.ADMIN_EMAIL || 'admin@opportunities.na',
    password: process.env.ADMIN_PASSWORD || 'Admin123!',
  },
  corsOrigins: (process.env.CORS_ORIGINS || '*')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  maxProfilesPerAccount: 2,
};

module.exports = config;
