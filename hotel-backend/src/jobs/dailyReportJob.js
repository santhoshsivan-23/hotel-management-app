/**
 * Optional end-of-day job (wire up with node-cron or an external
 * scheduler): snapshots the day's occupancy/revenue numbers.
 * Not started automatically - require and call `run()` from server.js
 * (or a scheduler) if/when this is needed.
 */
const reportService = require("../services/report.service");
const logger = require("../utils/logger");

async function run() {
  const today = new Date().toISOString().slice(0, 10);
  const [occupancy, revenue] = await Promise.all([
    reportService.occupancyReport(),
    reportService.revenueReport({ fromDate: `${today} 00:00:00`, toDate: `${today} 23:59:59` }),
  ]);

  logger.info(`[dailyReportJob] ${today} occupancy=${JSON.stringify(occupancy)} revenue=${JSON.stringify(revenue)}`);
  return { occupancy, revenue };
}

module.exports = { run };
