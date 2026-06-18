const express = require('express');
const { z } = require('zod');
const prisma = require('../db');
const { hashPassword, verifyPassword, signToken } = require('../utils/auth');
const { ensureSubscription } = require('../services/subscription');
const { authenticate } = require('../middleware/auth');
const { serializeUser } = require('../utils/serialize');

const router = express.Router();

const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  fullName: z.string().min(2),
  dateOfBirth: z.string().optional(),
  ageConfirmed: z.boolean(),
  acceptTerms: z.boolean(),
});

router.post('/signup', async (req, res) => {
  const parsed = signupSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const { email, password, fullName, dateOfBirth, ageConfirmed, acceptTerms } = parsed.data;

  if (!ageConfirmed) {
    return res.status(400).json({ error: 'You must confirm you are 18 or older' });
  }
  if (!acceptTerms) {
    return res.status(400).json({ error: 'You must accept the Terms & Privacy Policy' });
  }

  const existing = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
  if (existing) {
    return res.status(409).json({ error: 'An account with this email already exists' });
  }

  const user = await prisma.user.create({
    data: {
      email: email.toLowerCase(),
      passwordHash: await hashPassword(password),
      fullName,
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
      ageConfirmed,
      termsAcceptedAt: new Date(),
    },
  });

  await ensureSubscription(user.id);
  // Every account starts with one default profile.
  await prisma.profile.create({ data: { userId: user.id, name: fullName.split(' ')[0] || 'Profile 1' } });

  const full = await prisma.user.findUnique({
    where: { id: user.id },
    include: { subscription: true, profiles: true },
  });

  return res.status(201).json({ token: signToken(user), user: serializeUser(full) });
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

router.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid credentials' });
  }
  const { email, password } = parsed.data;
  const user = await prisma.user.findUnique({
    where: { email: email.toLowerCase() },
    include: { subscription: true, profiles: true },
  });
  if (!user || !(await verifyPassword(password, user.passwordHash))) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }
  if (user.status !== 'ACTIVE') {
    return res.status(403).json({ error: 'Account suspended. Contact support.' });
  }
  return res.json({ token: signToken(user), user: serializeUser(user) });
});

router.get('/me', authenticate, async (req, res) => {
  return res.json({ user: serializeUser(req.user) });
});

module.exports = router;
