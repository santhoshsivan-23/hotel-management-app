const express = require("express");
const router = express.Router();

router.use("/auth", require("./auth.routes"));
router.use("/guests", require("./guests.routes"));
router.use("/bookings", require("./bookings.routes"));
router.use("/rooms", require("./rooms.routes"));
router.use("/room-types", require("./roomTypes.routes"));
router.use("/amenities", require("./amenities.routes"));
router.use("/food-orders", require("./foodOrders.routes"));
router.use("/service-requests", require("./serviceRequests.routes"));
router.use("/payments", require("./payments.routes"));
router.use("/invoices", require("./invoices.routes"));
router.use("/maintenance", require("./maintenance.routes"));
router.use("/housekeeping", require("./housekeeping.routes"));
router.use("/taxes", require("./taxes.routes"));
router.use("/service-types", require("./serviceTypes.routes"));
router.use("/payment-methods", require("./paymentMethods.routes"));
router.use("/users", require("./users.routes"));
router.use("/roles", require("./roles.routes"));
router.use("/reports", require("./reports.routes"));
router.use("/hotel-settings", require("./hotelSettings.routes"));

// Everything the offline-first Flutter app pushes to / pulls from lives
// under /api/sync/* - see src/routes/sync/index.js
router.use("/sync", require("./sync"));

module.exports = router;
