const express = require('express');
const { z } = require('zod');
const prisma = require('../db');
const { hashPassword, verifyPassword, signToken } = require('../utils/auth');
const { ensureSubscription } = require('../services/subscription');
const { authenticate } = require('../middleware/auth');
const { serializeUser } = require('../utils/serialize');
const { ageFromDob, MINOR_AGE } = require('../utils/age');

const router = express.Router();

const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  fullName: z.string().min(2),
  dateOfBirth: z.string().min(1, 'Date of birth is required'),
  acceptTerms: z.boolean(),
  // Required only when the registrant is under 16.
  guardianName: z.string().optional(),
  guardianEmail: z.string().email().optional(),
  guardianConsent: z.boolean().optional(),
});

router.post('/signup', async (req, res) => {
  const parsed = signupSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const {
    email, password, fullName, dateOfBirth, acceptTerms,
    guardianName, guardianEmail, guardianConsent,
  } = parsed.data;

  const age = ageFromDob(dateOfBirth);
  if (age == null || age < 0 || age > 120) {
    return res.status(400).json({ error: 'Please enter a valid date of birth' });
  }
  if (!acceptTerms) {
    return res.status(400).json({ error: 'You must accept the Terms & Privacy Policy' });
  }

  const isMinor = age < MINOR_AGE;
  if (isMinor) {
    if (!guardianName || !guardianEmail) {
      return res.status(400).json({
        error: `Registrants under ${MINOR_AGE} must have a parent or guardian register on their behalf`,
      });
    }
    if (!guardianConsent) {
      return res.status(400).json({ error: 'A parent or guardian must give consent' });
    }
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
      dateOfBirth: new Date(dateOfBirth),
      ageConfirmed: true,
      termsAcceptedAt: new Date(),
      isMinor,
      guardianName: isMinor ? guardianName : null,
      guardianEmail: isMinor ? guardianEmail.toLowerCase() : null,
      guardianConsentAt: isMinor ? new Date() : null,
      // Parental controls are auto-enabled for minors and capped at their age.
      parentalControlsEnabled: isMinor,
      maxContentRating: isMinor ? age : 18,
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
