const express = require('express');
const prisma = require('../db');
const { authenticate } = require('../middleware/auth');
const { isEntitled } = require('../services/subscription');
const { canWatch, allowedRating } = require('../utils/age');
const { verifyPassword } = require('../utils/auth');

const router = express.Router();

router.use(authenticate);

// Browse sports + channels. Visible to any logged-in user, but stream URLs are
// only returned to entitled (paid & active) subscribers.
router.get('/sports', async (req, res) => {
  const sports = await prisma.sport.findMany({
    where: { active: true },
    orderBy: { sortOrder: 'asc' },
    include: {
      channels: { where: { active: true }, orderBy: { sortOrder: 'asc' } },
    },
  });

  const entitled = isEntitled(req.user.subscription);
  const payload = sports.map((s) => ({
    id: s.id,
    name: s.name,
    slug: s.slug,
    icon: s.icon,
    channels: s.channels.map((c) => {
      const ageOk = canWatch(req.user, c);
      const unlocked = entitled && ageOk;
      return {
        id: c.id,
        name: c.name,
        description: c.description,
        logo: c.logo,
        poster: c.poster,
        isLive: c.isLive,
        minAge: c.minAge,
        // streamUrl withheld unless entitled AND allowed by parental controls
        streamUrl: unlocked ? c.streamUrl : null,
        locked: !unlocked,
        // distinguishes a paywall lock from a parental-controls lock
        parentalBlocked: entitled && !ageOk,
      };
    }),
  }));

  return res.json({ entitled, allowedRating: allowedRating(req.user), sports: payload });
});

// Secure playback endpoint. Returns the stream URL only for entitled users
// whose parental-control rating permits the channel.
router.get('/channels/:id/play', async (req, res) => {
  if (!isEntitled(req.user.subscription)) {
    return res.status(402).json({
      error: 'Your subscription is inactive. Please pay N$200 to restore streaming access.',
      code: 'PAYMENT_REQUIRED',
    });
  }
  const channel = await prisma.channel.findFirst({
    where: { id: req.params.id, active: true },
  });
  if (!channel) return res.status(404).json({ error: 'Channel not found' });

  if (!canWatch(req.user, channel)) {
    // A guardian PIN can override the parental block for this request.
    const pin = req.query.pin || (req.body && req.body.pin);
    const pinOk = req.user.parentalPinHash && pin &&
      (await verifyPassword(String(pin), req.user.parentalPinHash));
    if (!pinOk) {
      return res.status(403).json({
        error: `This channel is rated ${channel.minAge}+ and is blocked by parental controls.`,
        code: 'PARENTAL_BLOCKED',
        minAge: channel.minAge,
        pinRequired: !!req.user.parentalPinHash,
      });
    }
  }

  return res.json({
    id: channel.id,
    name: channel.name,
    streamUrl: channel.streamUrl,
    isLive: channel.isLive,
  });
});

module.exports = router;
