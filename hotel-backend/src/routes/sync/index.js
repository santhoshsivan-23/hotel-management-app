const express = require("express");
const router = express.Router();
const authenticate = require("../../middleware/auth.middleware");

// Every sync route requires a valid device/user token - an offline device
// still needs to have logged in at least once before it has anything to
// sync with.
router.use(authenticate);

router.use("/guests", require("./syncGuests.routes"));
router.use("/bookings", require("./syncBookings.routes"));
router.use("/food-orders", require("./syncFoodOrders.routes"));
router.use("/service-requests", require("./syncServiceRequests.routes"));
router.use("/payments", require("./syncPayments.routes"));
router.use("/maintenance", require("./syncMaintenance.routes"));
router.use("/housekeeping", require("./syncHousekeeping.routes"));
router.use("/reference-data", require("./referenceData.routes"));

module.exports = router;
