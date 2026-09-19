const express = require("express");
const router = express.Router();
const controller = require("../controllers/payments.controller");
const validate = require("../middleware/validate.middleware");
const { create } = require("../validators/payment.validator");
const authenticate = require("../middleware/auth.middleware");

router.use(authenticate);

router.get("/booking/:bookingId", controller.listByBooking);
router.post("/", validate(create), controller.create);

module.exports = router;
