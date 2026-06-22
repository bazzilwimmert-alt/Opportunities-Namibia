const express = require('express');
const { z } = require('zod');
const prisma = require('../db');
const { authenticate, requireAdmin } = require('../middleware/auth');
const { activateForPeriod } = require('../services/membership');
const { ingestSource, ingestAll } = require('../services/ingest');
const { notifyPaymentConfirmed, notifyPaymentRejected } = require('../services/notify');

const router = express.Router();
router.use(authenticate, requireAdmin);

// ---- Dashboard stats ----
router.get('/stats', async (req, res) => {
  const [users, activeMembers, pendingClaims, jobs, sources, confirmed] =
    await Promise.all([
      prisma.user.count(),
      prisma.membership.count({ where: { status: 'ACTIVE' } }),
      prisma.paymentClaim.count({ where: { status: 'PENDING' } }),
      prisma.job.count({ where: { active: true } }),
      prisma.jobSource.count(),
      prisma.paymentClaim.findMany({ where: { status: 'CONFIRMED' } }),
    ]);
  const revenueCents = confirmed.reduce((sum, p) => sum + p.amountCents, 0);
  return res.json({
    users,
    activeMembers,
    pendingClaims,
    jobs,
    sources,
    revenueCents,
    currency: 'NAD',
  });
});

// ---- Users ----
router.get('/users', async (req, res) => {
  const users = await prisma.user.findMany({
    orderBy: { createdAt: 'desc' },
    include: { membership: true, profiles: true },
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

// Directly grant or revoke a user's access (independent of a payment claim).
router.post('/users/:id/access', async (req, res) => {
  const schema = z.object({
    action: z.enum(['grant', 'revoke']),
    months: z.number().int().min(1).max(24).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid action' });

  if (parsed.data.action === 'grant') {
    const m = await activateForPeriod(req.params.id, parsed.data.months);
    return res.json({ membership: m });
  }
  const m = await prisma.membership.update({
    where: { userId: req.params.id },
    data: { status: 'EXPIRED', currentPeriodEnd: new Date() },
  });
  return res.json({ membership: m });
});

// ---- Payment claims ----
router.get('/payments', async (req, res) => {
  const { status } = req.query;
  const where = status ? { status } : {};
  const payments = await prisma.paymentClaim.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    include: { user: { select: { id: true, email: true, fullName: true, phone: true } } },
  });
  return res.json({ payments });
});

// Confirm a payment -> grants a full membership period.
router.post('/payments/:id/confirm', async (req, res) => {
  const claim = await prisma.paymentClaim.findUnique({ where: { id: req.params.id } });
  if (!claim) return res.status(404).json({ error: 'Payment claim not found' });
  if (claim.status === 'CONFIRMED') return res.json({ claim });

  const membership = await activateForPeriod(claim.userId);
  const updated = await prisma.paymentClaim.update({
    where: { id: claim.id },
    data: {
      status: 'CONFIRMED',
      reviewedAt: new Date(),
      reviewedById: req.user.id,
      periodStart: new Date(),
      periodEnd: membership.currentPeriodEnd,
    },
  });
  const user = await prisma.user.findUnique({ where: { id: claim.userId } });
  if (user) await notifyPaymentConfirmed(user, membership.currentPeriodEnd);
  return res.json({ claim: updated, membership });
});

router.post('/payments/:id/reject', async (req, res) => {
  const claim = await prisma.paymentClaim.update({
    where: { id: req.params.id },
    data: { status: 'REJECTED', reviewedAt: new Date(), reviewedById: req.user.id },
  });
  const user = await prisma.user.findUnique({ where: { id: claim.userId } });
  if (user) await notifyPaymentRejected(user);
  return res.json({ claim });
});

// ---- Jobs (vacancies) ----
const jobSchema = z.object({
  title: z.string().min(1),
  company: z.string().min(1),
  location: z.string().optional(),
  category: z.string().optional(),
  type: z.enum(['FULL_TIME', 'PART_TIME', 'CONTRACT', 'TEMPORARY', 'INTERNSHIP']).optional(),
  skillLevel: z.enum(['SKILLED', 'UNSKILLED']).optional(),
  description: z.string().min(1),
  salary: z.string().optional(),
  applyUrl: z.string().optional(),
  applyEmail: z.string().optional(),
  contact: z.string().optional(),
  active: z.boolean().optional(),
});

router.get('/jobs', async (req, res) => {
  const jobs = await prisma.job.findMany({ orderBy: { postedAt: 'desc' }, take: 500 });
  return res.json({ jobs });
});

router.post('/jobs', async (req, res) => {
  const parsed = jobSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
  const job = await prisma.job.create({ data: { ...parsed.data, source: 'MANUAL' } });
  return res.status(201).json({ job });
});

router.patch('/jobs/:id', async (req, res) => {
  const parsed = jobSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
  const job = await prisma.job.update({ where: { id: req.params.id }, data: parsed.data });
  return res.json({ job });
});

router.delete('/jobs/:id', async (req, res) => {
  await prisma.job.delete({ where: { id: req.params.id } });
  return res.json({ ok: true });
});

// ---- Job sources (auto-ingestion) ----
const sourceSchema = z.object({
  name: z.string().min(1),
  type: z.enum(['RSS', 'LINKEDIN']).optional(),
  url: z.string().min(1),
  category: z.string().optional(),
  location: z.string().optional(),
  keywords: z.string().optional(),
  enabled: z.boolean().optional(),
});

router.get('/sources', async (req, res) => {
  const sources = await prisma.jobSource.findMany({ orderBy: { createdAt: 'asc' } });
  return res.json({ sources });
});

router.post('/sources', async (req, res) => {
  const parsed = sourceSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
  const source = await prisma.jobSource.create({ data: parsed.data });
  return res.status(201).json({ source });
});

router.patch('/sources/:id', async (req, res) => {
  const parsed = sourceSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
  const source = await prisma.jobSource.update({ where: { id: req.params.id }, data: parsed.data });
  return res.json({ source });
});

router.delete('/sources/:id', async (req, res) => {
  await prisma.jobSource.delete({ where: { id: req.params.id } });
  return res.json({ ok: true });
});

// Trigger ingestion now: a single source, or all enabled sources.
router.post('/sources/:id/fetch', async (req, res) => {
  const source = await prisma.jobSource.findUnique({ where: { id: req.params.id } });
  if (!source) return res.status(404).json({ error: 'Source not found' });
  const result = await ingestSource(source);
  return res.json({ result });
});

router.post('/ingest', async (req, res) => {
  const result = await ingestAll();
  return res.json({ result });
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
