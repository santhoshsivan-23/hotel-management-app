const express = require("express");
const router = express.Router();
const controller = require("../controllers/invoices.controller");
const authenticate = require("../middleware/auth.middleware");

router.use(authenticate);

router.get("/booking/:bookingId", controller.getByBooking);
router.post("/booking/:bookingId/generate", controller.generate);

module.exports = router;
