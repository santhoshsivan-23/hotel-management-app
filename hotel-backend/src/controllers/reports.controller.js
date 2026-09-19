const asyncHandler = require("../utils/asyncHandler");
const reportService = require("../services/report.service");

const range = (req) => ({ fromDate: req.query.from_date, toDate: req.query.to_date });

const bookingReport = asyncHandler(async (req, res) => res.json(await reportService.bookingReport(range(req))));
const occupancyReport = asyncHandler(async (req, res) => res.json(await reportService.occupancyReport()));
const revenueReport = asyncHandler(async (req, res) => res.json(await reportService.revenueReport(range(req))));
const foodSalesReport = asyncHandler(async (req, res) => res.json(await reportService.foodSalesReport(range(req))));
const roomServicesReport = asyncHandler(async (req, res) => res.json(await reportService.roomServicesReport(range(req))));
const paymentReport = asyncHandler(async (req, res) => res.json(await reportService.paymentReport(range(req))));
const outstandingReport = asyncHandler(async (req, res) => res.json(await reportService.outstandingReport()));

module.exports = {
  bookingReport, occupancyReport, revenueReport, foodSalesReport, roomServicesReport, paymentReport, outstandingReport,
};
