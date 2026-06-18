const express = require('express');
const prisma = require('../db');
const config = require('../config');

const router = express.Router();

// Public, unauthenticated app config (branding, pricing, legal copy).
router.get('/config', async (req, res) => {
  const settings = await prisma.setting.findMany();
  const map = Object.fromEntries(settings.map((s) => [s.key, s.value]));
  return res.json({
    appName: map.appName || 'Bax',
    tagline: map.tagline || 'All sports. One subscription.',
    price: {
      cents: config.subscription.priceCents,
      currency: config.subscription.currency,
      display: `N$${(config.subscription.priceCents / 100).toFixed(0)}/month`,
    },
    maxProfiles: config.maxProfilesPerAccount,
    termsUrl: map.termsUrl || '',
    privacyUrl: map.privacyUrl || '',
    supportEmail: map.supportEmail || 'support@bax.tv',
  });
});

module.exports = router;
