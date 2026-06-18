const express = require('express');
const prisma = require('../db');
const config = require('../config');
const payToday = require('../services/payToday');
const {
  ensureSubscription,
  activateForPaidPeriod,
  MONTH_MS,
} = require('../services/subscription');
const { authenticate } = require('../middleware/auth');
const { serializeSubscription } = require('../utils/serialize');

const router = express.Router();

router.use(authenticate);

router.get('/', async (req, res) => {
  const sub = await ensureSubscription(req.user.id);
  return res.json({
    subscription: serializeSubscription(sub),
    price: { cents: config.subscription.priceCents, currency: config.subscription.currency },
  });
});

// Start a subscription payment. Creates a pending Payment + PayToday charge and
// returns a checkout URL. On confirmation (webhook or sandbox confirm) the
// subscription is activated for one month.
router.post('/checkout', async (req, res) => {
  await ensureSubscription(req.user.id);
  const periodStart = new Date();
  const periodEnd = new Date(Date.now() + MONTH_MS);

  const payment = await prisma.payment.create({
    data: {
      userId: req.user.id,
      amountCents: config.subscription.priceCents,
      currency: config.subscription.currency,
      status: 'PENDING',
      provider: 'paytoday',
      periodStart,
      periodEnd,
    },
  });

  const charge = await payToday.createCharge({
    amountCents: config.subscription.priceCents,
    currency: config.subscription.currency,
    reference: payment.id,
    customerEmail: req.user.email,
    returnUrl: req.body.returnUrl,
  });

  await prisma.payment.update({
    where: { id: payment.id },
    data: { providerRef: charge.providerRef },
  });

  return res.json({
    paymentId: payment.id,
    providerRef: charge.providerRef,
    checkoutUrl: charge.checkoutUrl,
    sandbox: !!charge.sandbox,
  });
});

// Sandbox-only: simulate a successful PayToday payment confirmation.
router.post('/sandbox/confirm', async (req, res) => {
  if (!payToday.isSandbox) {
    return res.status(400).json({ error: 'Sandbox confirm is disabled in live mode' });
  }
  const { paymentId } = req.body;
  const payment = await prisma.payment.findFirst({
    where: { id: paymentId, userId: req.user.id },
  });
  if (!payment) return res.status(404).json({ error: 'Payment not found' });
  if (payment.status === 'PAID') {
    return res.json({ ok: true, alreadyPaid: true });
  }

  await prisma.payment.update({ where: { id: payment.id }, data: { status: 'PAID' } });
  const sub = await activateForPaidPeriod(req.user.id, payment.periodEnd);
  return res.json({ ok: true, subscription: serializeSubscription(sub) });
});

router.post('/cancel', async (req, res) => {
  const sub = await prisma.subscription.update({
    where: { userId: req.user.id },
    data: { cancelAtPeriodEnd: true },
  });
  return res.json({ subscription: serializeSubscription(sub) });
});

router.post('/resume', async (req, res) => {
  const sub = await prisma.subscription.update({
    where: { userId: req.user.id },
    data: { cancelAtPeriodEnd: false },
  });
  return res.json({ subscription: serializeSubscription(sub) });
});

router.get('/payments', async (req, res) => {
  const payments = await prisma.payment.findMany({
    where: { userId: req.user.id },
    orderBy: { createdAt: 'desc' },
  });
  return res.json({ payments });
});

module.exports = router;
