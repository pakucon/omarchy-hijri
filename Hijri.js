// Islamic (Hijri) calendar conversion for the Omarchy Hijri Calendar plugin.
//
// Uses the arithmetical tabular civil calendar from Reingold & Dershowitz,
// "Calendrical Calculations" (the same basis as most software converters).
// It is deterministic and self-contained (no network, no external binary).
//
// NOTE: the tabular calendar can differ by up to 1 day from moon-sighting
// based calendars such as Umm al-Qura. That is expected for this approach.

function islamicEpoch() {
  return 227014; // Rata Die (fixed) date of 1 Muharram 1 AH
}

// Gregorian (proleptic) year/month/day -> Rata Die fixed date.
function gregorianToFixed(y, m, d) {
  var a = Math.floor((14 - m) / 12);
  var yy = y + 4800 - a;
  var mm = m + 12 * a - 3;
  var jdn = d + Math.floor((153 * mm + 2) / 5) + 365 * yy + Math.floor(yy / 4)
    - Math.floor(yy / 100) + Math.floor(yy / 400) - 32045;
  return jdn - 1721425;
}

// Hijri year/month/day -> Rata Die fixed date.
function fixedFromIslamic(y, m, d) {
  return islamicEpoch() - 1 + 354 * (y - 1) + Math.floor((3 + 11 * y) / 30)
    + 29 * (m - 1) + Math.floor(m / 2) + d;
}

// Rata Die fixed date -> { y, m, d } Hijri.
function islamicFromFixed(fixed) {
  var year = Math.floor((30 * (fixed - islamicEpoch()) + 10646) / 10631);
  var month = Math.min(12, 1 + Math.floor((fixed - fixedFromIslamic(year, 1, 1)) / 29.5));
  var day = fixed - fixedFromIslamic(year, month, 1) + 1;
  return { y: year, m: month, d: day };
}

// JS Date -> { y, m, d } Hijri.
function hijriFromDate(date) {
  return islamicFromFixed(gregorianToFixed(date.getFullYear(), date.getMonth() + 1, date.getDate()));
}

// Number of days in a Hijri month (29 or 30).
function monthLength(y, m) {
  if (m === 12) return fixedFromIslamic(y + 1, 1, 1) - fixedFromIslamic(y, 12, 1);
  return fixedFromIslamic(y, m + 1, 1) - fixedFromIslamic(y, m, 1);
}

// Weekday of a Hijri date: 0 = Monday ... 6 = Sunday (Rata Die 1 = Monday).
function dayOfWeek(y, m, d) {
  var fixed = fixedFromIslamic(y, m, d);
  return ((fixed - 1) % 7 + 7) % 7;
}

// Step a (year, month) pair by delta months, wrapping at year boundaries.
function stepMonth(y, m, delta) {
  var total = (y - 1) * 12 + (m - 1) + delta;
  var ny = Math.floor(total / 12) + 1;
  var nm = (total % 12 + 12) % 12 + 1;
  return { year: ny, month: nm };
}

// Indonesian month names.
var MONTHS_ID = [
  "Muharram", "Safar", "Rabiul Awal", "Rabiul Akhir",
  "Jumadil Awal", "Jumadil Akhir", "Rajab", "Sya'ban",
  "Ramadhan", "Syawal", "Dzulqa'dah", "Dzulhijjah"
];

// Shorter forms for the bar label.
var MONTHS_SHORT_ID = [
  "Muharram", "Safar", "Rab. Awal", "Rab. Akhir",
  "Jum. Awal", "Jum. Akhir", "Rajab", "Sya'ban",
  "Ramadhan", "Syawal", "Dzulqa'dah", "Dzulhijjah"
];

// Shorter English forms for the bar label.
var MONTHS_SHORT_EN = [
  "Muh", "Saf", "Rab. I", "Rab. II",
  "Jum. I", "Jum. II", "Raj", "Sha'ban",
  "Ramadan", "Shawwal", "Dhu-Qi'd", "Dhu-Hij"
];

// Shorter Arabic forms for the bar label.
var MONTHS_SHORT_AR = [
  "محر", "صفر", "رب١", "رب٢",
  "جم١", "جم٢", "رجب", "شعب",
  "رمض", "شوال", "ذوق", "ذوح"
];
