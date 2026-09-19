/**
 * Minimal, dependency-free smoke tests for the date helpers - run with:
 *   node tests/unit/dateHelpers.test.js
 * (No test framework wired up; swap in Jest/Mocha if the project grows.)
 */
const assert = require("assert");
const { nightsBetween, rangesOverlap } = require("../../src/utils/dateHelpers");

assert.strictEqual(nightsBetween("2026-09-10", "2026-09-13"), 3);
assert.strictEqual(nightsBetween("2026-09-10", "2026-09-11"), 1);

assert.strictEqual(rangesOverlap("2026-09-10", "2026-09-13", "2026-09-12", "2026-09-15"), true);
assert.strictEqual(rangesOverlap("2026-09-10", "2026-09-13", "2026-09-13", "2026-09-15"), false);
assert.strictEqual(rangesOverlap("2026-09-10", "2026-09-13", "2026-09-05", "2026-09-10"), false);

console.log("dateHelpers.test.js: all assertions passed");
