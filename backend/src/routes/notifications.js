const express = require('express');
const prisma = require('../db');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// List the current user's notifications (newest first) + unread count.
router.get('/', async (req, res) => {
  const [notifications, unread] = await Promise.all([
    prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    }),
    prisma.notification.count({ where: { userId: req.user.id, read: false } }),
  ]);
  return res.json({ notifications, unread });
});

// Mark one notification read.
router.post('/:id/read', async (req, res) => {
  const n = await prisma.notification.findUnique({ where: { id: req.params.id } });
  if (!n || n.userId !== req.user.id) {
    return res.status(404).json({ error: 'Not found' });
  }
  await prisma.notification.update({ where: { id: n.id }, data: { read: true } });
  return res.json({ ok: true });
});

// Mark all of the user's notifications read.
router.post('/read-all', async (req, res) => {
  await prisma.notification.updateMany({
    where: { userId: req.user.id, read: false },
    data: { read: true },
  });
  return res.json({ ok: true });
});

module.exports = router;
