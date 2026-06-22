const express = require('express');
const prisma = require('../db');
const { authenticate } = require('../middleware/auth');
const { hasAccess } = require('../services/membership');
const { serializeJob } = require('../utils/serialize');

const router = express.Router();
router.use(authenticate);

// List / search vacancies. Members see full details; non-members get locked
// previews (title/company/category only) until their payment is confirmed.
router.get('/', async (req, res) => {
  const { q, category, skillLevel, type, location } = req.query;
  const where = { active: true };
  if (category) where.category = category;
  if (skillLevel) where.skillLevel = skillLevel;
  if (type) where.type = type;
  if (location) where.location = { contains: location };
  if (q) {
    where.OR = [
      { title: { contains: q } },
      { company: { contains: q } },
      { description: { contains: q } },
      { category: { contains: q } },
    ];
  }

  const jobs = await prisma.job.findMany({
    where,
    orderBy: { postedAt: 'desc' },
    take: 200,
  });
  const access = hasAccess(req.user.membership);
  return res.json({
    access,
    total: jobs.length,
    jobs: jobs.map((j) => serializeJob(j, { full: access })),
  });
});

// Distinct categories for filter chips.
router.get('/categories', async (req, res) => {
  const rows = await prisma.job.findMany({
    where: { active: true },
    distinct: ['category'],
    select: { category: true },
    orderBy: { category: 'asc' },
  });
  return res.json({ categories: rows.map((r) => r.category) });
});

router.get('/:id', async (req, res) => {
  const job = await prisma.job.findFirst({
    where: { id: req.params.id, active: true },
  });
  if (!job) return res.status(404).json({ error: 'Vacancy not found' });
  const access = hasAccess(req.user.membership);
  return res.json({ access, job: serializeJob(job, { full: access }) });
});

module.exports = router;
