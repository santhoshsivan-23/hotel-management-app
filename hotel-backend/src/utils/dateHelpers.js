function toMySQLDateTime(date) {
  const d = date instanceof Date ? date : new Date(date);
  return d.toISOString().slice(0, 19).replace("T", " ");
}

function nightsBetween(checkIn, checkOut) {
  const inDate = new Date(checkIn);
  const outDate = new Date(checkOut);
  const diffMs = outDate.getTime() - inDate.getTime();
  return Math.max(1, Math.round(diffMs / (1000 * 60 * 60 * 24)));
}

/**
 * Two date ranges [aStart, aEnd) and [bStart, bEnd) overlap when:
 *   aStart < bEnd AND aEnd > bStart
 * This is the standard "booking availability" overlap check used across
 * the reservations module.
 */
function rangesOverlap(aStart, aEnd, bStart, bEnd) {
  return new Date(aStart) < new Date(bEnd) && new Date(aEnd) > new Date(bStart);
}

function now() {
  return toMySQLDateTime(new Date());
}

module.exports = { toMySQLDateTime, nightsBetween, rangesOverlap, now };
