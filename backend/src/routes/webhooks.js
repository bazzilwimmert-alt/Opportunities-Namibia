const express = require('express');
const prisma = require('../db');
const payToday = require('../services/payToday');
const { activateForPaidPeriod } = require('../services/subscription');

const router = express.Router();

// PayToday webhook. Configured in the PayToday dashboard to point here.
// Uses the raw body (mounted with express.raw in index.js) for signature checks.
router.post('/paytoday', async (req, res) => {
  const signature = req.headers['x-paytoday-signature'];
  const raw = req.body instanceof Buffer ? req.body.toString('utf8') : JSON.stringify(req.body);

  if (!payToday.verifyWebhook(raw, signature)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  let event;
  try {
    event = JSON.parse(raw);
  } catch {
    return res.status(400).json({ error: 'Invalid payload' });
  }

  // Expected shape: { type, data: { reference, status, transaction_ref } }
  const reference = event?.data?.reference;
  const status = event?.data?.status;
  if (!reference) return res.status(400).json({ error: 'Missing reference' });

  const payment = await prisma.payment.findUnique({ where: { id: reference } });
  if (!payment) return res.status(404).json({ error: 'Unknown payment' });

  if (status === 'paid' || status === 'success') {
    await prisma.payment.update({
      where: { id: payment.id },
      data: { status: 'PAID', providerRef: event?.data?.transaction_ref || payment.providerRef },
    });
    await activateForPaidPeriod(payment.userId, payment.periodEnd);
  } else if (status === 'failed') {
    await prisma.payment.update({ where: { id: payment.id }, data: { status: 'FAILED' } });
  }

  return res.json({ received: true });
});

module.exports = router;
