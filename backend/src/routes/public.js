const express = require('express');
const prisma = require('../db');
const config = require('../config');

const router = express.Router();

// Public, unauthenticated app config (branding, pricing, payment info, legal).
router.get('/config', async (req, res) => {
  const settings = await prisma.setting.findMany();
  const map = Object.fromEntries(settings.map((s) => [s.key, s.value]));
  const months = config.membership.periodMonths;
  return res.json({
    appName: map.appName || 'Opportunities Namibia',
    tagline: map.tagline || 'Every Namibian job. One membership.',
    price: {
      cents: config.membership.priceCents,
      currency: config.membership.currency,
      periodMonths: months,
      display: `N$${(config.membership.priceCents / 100).toFixed(0)} / ${months} months`,
    },
    payment: {
      phone: map.paymentPhone || config.payment.phone,
      accountName: map.paymentAccountName || config.payment.accountName,
    },
    maxProfiles: config.maxProfilesPerAccount,
    termsUrl: map.termsUrl || '',
    privacyUrl: map.privacyUrl || '',
    supportEmail: map.supportEmail || 'support@opportunities.na',
  });
});

module.exports = router;
