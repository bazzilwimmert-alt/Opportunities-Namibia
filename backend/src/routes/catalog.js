const express = require('express');
const prisma = require('../db');
const { authenticate } = require('../middleware/auth');
const { isEntitled } = require('../services/subscription');

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
    channels: s.channels.map((c) => ({
      id: c.id,
      name: c.name,
      description: c.description,
      logo: c.logo,
      poster: c.poster,
      isLive: c.isLive,
      // streamUrl withheld unless entitled
      streamUrl: entitled ? c.streamUrl : null,
      locked: !entitled,
    })),
  }));

  return res.json({ entitled, sports: payload });
});

// Secure playback endpoint. Returns the stream URL only for entitled users.
// This is the enforcement point that revokes streaming rights when unpaid.
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
  return res.json({
    id: channel.id,
    name: channel.name,
    streamUrl: channel.streamUrl,
    isLive: channel.isLive,
  });
});

module.exports = router;
