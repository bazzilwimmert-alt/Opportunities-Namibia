// Age helpers used by registration and parental controls.

const MINOR_AGE = 16; // under this age a guardian must register/consent

function ageFromDob(dob) {
  if (!dob) return null;
  const birth = dob instanceof Date ? dob : new Date(dob);
  if (Number.isNaN(birth.getTime())) return null;
  const now = new Date();
  let age = now.getFullYear() - birth.getFullYear();
  const m = now.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) age -= 1;
  return age;
}

// Highest channel minAge this user may watch right now.
function allowedRating(user) {
  const age = ageFromDob(user.dateOfBirth);
  if (user.parentalControlsEnabled) {
    // Cap by the parental limit, never above the user's real age.
    if (age == null) return user.maxContentRating;
    return Math.min(user.maxContentRating, age);
  }
  return age == null ? 18 : age;
}

function canWatch(user, channel) {
  return (channel.minAge || 0) <= allowedRating(user);
}

module.exports = { MINOR_AGE, ageFromDob, allowedRating, canWatch };
