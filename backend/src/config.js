require('dotenv').config();

const config = {
  port: parseInt(process.env.PORT || '4000', 10),
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  subscription: {
    priceCents: parseInt(process.env.SUBSCRIPTION_PRICE_CENTS || '20000', 10),
    currency: process.env.SUBSCRIPTION_CURRENCY || 'NAD',
  },
  payToday: {
    mode: process.env.PAYTODAY_MODE || 'sandbox',
    apiBase: process.env.PAYTODAY_API_BASE || 'https://api.paytoday.com.na',
    merchantId: process.env.PAYTODAY_MERCHANT_ID || '',
    apiKey: process.env.PAYTODAY_API_KEY || '',
    webhookSecret: process.env.PAYTODAY_WEBHOOK_SECRET || 'sandbox-webhook-secret',
  },
  admin: {
    email: process.env.ADMIN_EMAIL || 'admin@bax.tv',
    password: process.env.ADMIN_PASSWORD || 'Admin123!',
  },
  corsOrigins: (process.env.CORS_ORIGINS || '*')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  maxProfilesPerAccount: 2,
};

module.exports = config;
