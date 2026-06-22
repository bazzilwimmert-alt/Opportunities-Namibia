const express = require('express');
const { z } = require('zod');
const prisma = require('../db');
const config = require('../config');
const { ensureMembership, markPending } = require('../services/membership');
const { authenticate } = require('../middleware/auth');
const { serializeMembership } = require('../utils/serialize');

const router = express.Router();
router.use(authenticate);

function paymentInfo() {
  return {
    priceCents: config.membership.priceCents,
    currency: config.membership.currency,
    periodMonths: config.membership.periodMonths,
    phone: config.payment.phone,
    accountName: config.payment.accountName,
  };
}

router.get('/', async (req, res) => {
  const m = await ensureMembership(req.user.id);
  const latestClaim = await prisma.paymentClaim.findFirst({
    where: { userId: req.user.id },
    orderBy: { createdAt: 'desc' },
  });
  return res.json({
    membership: serializeMembership(m),
    payment: paymentInfo(),
    latestClaim,
  });
});

const claimSchema = z.object({
  reference: z.string().max(120).optional(),
  payerPhone: z.string().max(40).optional(),
});

// A member tells us they have paid the admin's mobile number. This creates a
// PENDING claim for an admin to confirm; it does NOT grant access by itself.
router.post('/pay', async (req, res) => {
  const parsed = claimSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const open = await prisma.paymentClaim.findFirst({
    where: { userId: req.user.id, status: 'PENDING' },
  });
  if (open) {
    return res.status(409).json({
      error: 'You already have a payment awaiting confirmation by the admin.',
    });
  }
  const claim = await prisma.paymentClaim.create({
    data: {
      userId: req.user.id,
      amountCents: config.membership.priceCents,
      currency: config.membership.currency,
      reference: parsed.data.reference || null,
      payerPhone: parsed.data.payerPhone || null,
      status: 'PENDING',
    },
  });
  const m = await markPending(req.user.id);
  return res.status(201).json({ claim, membership: serializeMembership(m) });
});

router.get('/payments', async (req, res) => {
  const payments = await prisma.paymentClaim.findMany({
    where: { userId: req.user.id },
    orderBy: { createdAt: 'desc' },
  });
  return res.json({ payments });
});

module.exports = router;
