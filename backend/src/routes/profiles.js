const express = require('express');
const { z } = require('zod');
const prisma = require('../db');
const config = require('../config');
const { authenticate } = require('../middleware/auth');
const { serializeProfile } = require('../utils/serialize');

const router = express.Router();

router.use(authenticate);

router.get('/', async (req, res) => {
  const profiles = await prisma.profile.findMany({
    where: { userId: req.user.id },
    orderBy: { createdAt: 'asc' },
  });
  return res.json({ profiles: profiles.map(serializeProfile) });
});

const profileSchema = z.object({
  name: z.string().min(1).max(30),
  avatar: z.string().optional(),
  headline: z.string().max(120).optional(),
});

router.post('/', async (req, res) => {
  const parsed = profileSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const count = await prisma.profile.count({ where: { userId: req.user.id } });
  if (count >= config.maxProfilesPerAccount) {
    return res
      .status(400)
      .json({ error: `You can create at most ${config.maxProfilesPerAccount} profiles` });
  }
  const profile = await prisma.profile.create({
    data: { userId: req.user.id, ...parsed.data },
  });
  return res.status(201).json({ profile: serializeProfile(profile) });
});

router.patch('/:id', async (req, res) => {
  const parsed = profileSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const existing = await prisma.profile.findFirst({
    where: { id: req.params.id, userId: req.user.id },
  });
  if (!existing) return res.status(404).json({ error: 'Profile not found' });
  const profile = await prisma.profile.update({
    where: { id: req.params.id },
    data: parsed.data,
  });
  return res.json({ profile: serializeProfile(profile) });
});

router.delete('/:id', async (req, res) => {
  const existing = await prisma.profile.findFirst({
    where: { id: req.params.id, userId: req.user.id },
  });
  if (!existing) return res.status(404).json({ error: 'Profile not found' });
  const count = await prisma.profile.count({ where: { userId: req.user.id } });
  if (count <= 1) {
    return res.status(400).json({ error: 'You must keep at least one profile' });
  }
  await prisma.profile.delete({ where: { id: req.params.id } });
  return res.json({ ok: true });
});

module.exports = router;
