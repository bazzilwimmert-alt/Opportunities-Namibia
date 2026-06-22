const { isEntitled } = require('../services/subscription');
const { ageFromDob, allowedRating } = require('./age');

function serializeUser(user) {
  if (!user) return null;
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    role: user.role,
    status: user.status,
    ageConfirmed: user.ageConfirmed,
    dateOfBirth: user.dateOfBirth,
    age: ageFromDob(user.dateOfBirth),
    isMinor: user.isMinor,
    guardianName: user.guardianName,
    guardianEmail: user.guardianEmail,
    parentalControlsEnabled: user.parentalControlsEnabled,
    maxContentRating: user.maxContentRating,
    parentalPinSet: !!user.parentalPinHash,
    allowedRating: allowedRating(user),
    createdAt: user.createdAt,
    subscription: serializeSubscription(user.subscription),
    entitled: isEntitled(user.subscription),
    profiles: (user.profiles || []).map(serializeProfile),
  };
}

function serializeSubscription(sub) {
  if (!sub) return null;
  return {
    status: sub.status,
    priceCents: sub.priceCents,
    currency: sub.currency,
    currentPeriodEnd: sub.currentPeriodEnd,
    cancelAtPeriodEnd: sub.cancelAtPeriodEnd,
  };
}

function serializeProfile(p) {
  return { id: p.id, name: p.name, avatar: p.avatar, isKids: p.isKids };
}

module.exports = { serializeUser, serializeSubscription, serializeProfile };
