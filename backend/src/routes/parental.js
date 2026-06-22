const express = require('express');
const { z } = require('zod');
const prisma = require('../db');
const { authenticate } = require('../middleware/auth');
const { hashPassword, verifyPassword } = require('../utils/auth');
const { serializeUser } = require('../utils/serialize');

const router = express.Router();
router.use(authenticate);

async function reloadUser(id) {
  return prisma.user.findUnique({
    where: { id },
    include: { subscription: true, profiles: true },
  });
}

// Current parental-control state for the account.
router.get('/', (req, res) => {
  return res.json({
    parentalControlsEnabled: req.user.parentalControlsEnabled,
    maxContentRating: req.user.maxContentRating,
    parentalPinSet: !!req.user.parentalPinHash,
    isMinor: req.user.isMinor,
  });
});

const settingsSchema = z.object({
  enabled: z.boolean().optional(),
  maxContentRating: z.number().int().min(0).max(18).optional(),
  pin: z.string().optional(), // required when a PIN is already set
});

// Update parental settings. When a PIN exists it must be supplied; minors can
// never turn parental controls off.
router.put('/', async (req, res) => {
  const parsed = settingsSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const { enabled, maxContentRating, pin } = parsed.data;

  if (req.user.parentalPinHash) {
    const ok = pin && (await verifyPassword(String(pin), req.user.parentalPinHash));
    if (!ok) return res.status(403).json({ error: 'Incorrect parental PIN', code: 'PIN_REQUIRED' });
  }
  if (req.user.isMinor && enabled === false) {
    return res.status(403).json({ error: 'Parental controls cannot be disabled on a minor account' });
  }

  const data = {};
  if (enabled !== undefined) data.parentalControlsEnabled = enabled;
  if (maxContentRating !== undefined) data.maxContentRating = maxContentRating;
  await prisma.user.update({ where: { id: req.user.id }, data });

  return res.json({ user: serializeUser(await reloadUser(req.user.id)) });
});

const pinSchema = z.object({
  currentPin: z.string().optional(),
  newPin: z.string().regex(/^\d{4,6}$/, 'PIN must be 4-6 digits').optional(),
  clear: z.boolean().optional(),
});

// Set, change, or clear the guardian PIN.
router.put('/pin', async (req, res) => {
  const parsed = pinSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message });
  }
  const { currentPin, newPin, clear } = parsed.data;

  if (req.user.parentalPinHash) {
    const ok = currentPin && (await verifyPassword(String(currentPin), req.user.parentalPinHash));
    if (!ok) return res.status(403).json({ error: 'Incorrect current PIN', code: 'PIN_REQUIRED' });
  }

  if (clear) {
    if (req.user.isMinor) {
      return res.status(403).json({ error: 'A minor account must keep a guardian PIN' });
    }
    await prisma.user.update({ where: { id: req.user.id }, data: { parentalPinHash: null } });
  } else {
    if (!newPin) return res.status(400).json({ error: 'A new PIN is required' });
    await prisma.user.update({
      where: { id: req.user.id },
      data: { parentalPinHash: await hashPassword(newPin) },
    });
  }

  return res.json({ user: serializeUser(await reloadUser(req.user.id)) });
});

module.exports = router;
