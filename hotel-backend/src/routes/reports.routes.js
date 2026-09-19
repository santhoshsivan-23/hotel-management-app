const express = require("express");
const router = express.Router();
const controller = require("../controllers/reports.controller");
const authenticate = require("../middleware/auth.middleware");
const requireRole = require("../middleware/role.middleware");
const { ROLES } = require("../config/constants");

router.use(authenticate, requireRole(ROLES.ADMIN, ROLES.MANAGER));

router.get("/bookings", controller.bookingReport);
router.get("/occupancy", controller.occupancyReport);
router.get("/revenue", controller.revenueReport);
router.get("/food-sales", controller.foodSalesReport);
router.get("/room-services", controller.roomServicesReport);
router.get("/payments", controller.paymentReport);
router.get("/outstanding", controller.outstandingReport);

module.exports = router;
