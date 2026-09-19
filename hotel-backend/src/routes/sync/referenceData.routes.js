const express = require("express");
const router = express.Router();
const controller = require("../../controllers/sync/referenceData.controller");

router.get("/", controller.pull);
router.get("/bookings", controller.pullBookings);

module.exports = router;
