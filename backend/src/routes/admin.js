const express = require('express');
const { z } = require('zod');
const prisma = require('../db');
const { authenticate, requireAdmin } = require('../middleware/auth');
const { activateForPaidPeriod, MONTH_MS } = require('../services/subscription');

const router = express.Router();

router.use(authenticate, requireAdmin);

// ---- Dashboard stats ----
router.get('/stats', async (req, res) => {
  const [users, activeSubs, pastDue, sports, channels, payments] = await Promise.all([
    prisma.user.count(),
    prisma.subscription.count({ where: { status: 'ACTIVE' } }),
    prisma.subscription.count({ where: { status: 'PAST_DUE' } }),
    prisma.sport.count(),
    prisma.channel.count(),
    prisma.payment.findMany({ where: { status: 'PAID' } }),
  ]);
  const revenueCents = payments.reduce((sum, p) => sum + p.amountCents, 0);
  return res.json({
    users,
    activeSubscriptions: activeSubs,
    pastDueSubscriptions: pastDue,
    sports,
    channels,
    revenueCents,
    currency: 'NAD',
  });
});

// ---- Users ----
router.get('/users', async (req, res) => {
  const users = await prisma.user.findMany({
    orderBy: { createdAt: 'desc' },
    include: { subscription: true, profiles: true },
  });
  return res.json({ users });
});

router.patch('/users/:id', async (req, res) => {
  const schema = z.object({
    role: z.enum(['USER', 'ADMIN']).optional(),
    status: z.enum(['ACTIVE', 'SUSPENDED']).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid payload' });
  const user = await prisma.user.update({ where: { id: req.params.id }, data: parsed.data });
  return res.json({ user });
});

// Admin can grant/revoke a user's streaming rights directly.
router.post('/users/:id/subscription', async (req, res) => {
  const schema = z.object({ action: z.enum(['grant', 'revoke']) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid action' });

  if (parsed.data.action === 'grant') {
    const sub = await activateForPaidPeriod(req.params.id, new Date(Date.now() + MONTH_MS));
    return res.json({ subscription: sub });
  }
  const sub = await prisma.subscription.update({
    where: { userId: req.params.id },
    data: { status: 'PAST_DUE', currentPeriodEnd: new Date() },
  });
  return res.json({ subscription: sub });
});

// ---- Sports ----
const sportSchema = z.object({
  name: z.string().min(1),
  slug: z.string().min(1),
  icon: z.string().optional(),
  sortOrder: z.number().optional(),
  active: z.boolean().optional(),
});

router.post('/sports', async (req, res) => {
  const parsed = sportSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
  const sport = await prisma.sport.create({ data: parsed.data });
  return res.status(201).json({ sport });
});

router.patch('/sports/:id', async (req, res) => {
  const parsed = sportSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
  const sport = await prisma.sport.update({ where: { id: req.params.id }, data: parsed.data });
  return res.json({ sport });
});

router.delete('/sports/:id', async (req, res) => {
  await prisma.sport.delete({ where: { id: req.params.id } });
  return res.json({ ok: true });
});

// ---- Channels ----
const channelSchema = z.object({
  sportId: z.string().min(1),
  name: z.string().min(1),
  description: z.string().optional(),
  logo: z.string().optional(),
  streamUrl: z.string().min(1),
  poster: z.string().optional(),
  isLive: z.boolean().optional(),
  active: z.boolean().optional(),
  sortOrder: z.number().optional(),
  minAge: z.number().int().min(0).max(18).optional(),
});

router.post('/channels', async (req, res) => {
  const parsed = channelSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
  const channel = await prisma.channel.create({ data: parsed.data });
  return res.status(201).json({ channel });
});

router.patch('/channels/:id', async (req, res) => {
  const parsed = channelSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
  const channel = await prisma.channel.update({ where: { id: req.params.id }, data: parsed.data });
  return res.json({ channel });
});

router.delete('/channels/:id', async (req, res) => {
  await prisma.channel.delete({ where: { id: req.params.id } });
  return res.json({ ok: true });
});

// ---- Platform settings (editable online) ----
router.get('/settings', async (req, res) => {
  const settings = await prisma.setting.findMany();
  return res.json({ settings });
});

router.put('/settings/:key', async (req, res) => {
  const schema = z.object({ value: z.string() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid value' });
  const setting = await prisma.setting.upsert({
    where: { key: req.params.key },
    create: { key: req.params.key, value: parsed.data.value },
    update: { value: parsed.data.value },
  });
  return res.json({ setting });
});

module.exports = router;
