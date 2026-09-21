const express = require("express");
const router = express.Router();
const controller = require("../controllers/bookings.controller");
const validate = require("../middleware/validate.middleware");
const { create, updateStatus, changeRoom, extendStay } = require("../validators/booking.validator");
const authenticate = require("../middleware/auth.middleware");

router.use(authenticate);

router.get("/", controller.list);
router.get("/:id", controller.getById);
router.get("/:id/running-bill", controller.runningBill);
router.post("/", validate(create), controller.create);
router.patch("/:id/status", validate(updateStatus), controller.updateStatus);
router.post("/:id/cancel", controller.cancel);
router.post("/:id/checkin", controller.checkin);
router.post("/:id/checkout", controller.checkout);
router.post("/:id/reopen", controller.reopen);
router.post("/:id/change-room", validate(changeRoom), controller.changeRoom);
router.post("/:id/extend", validate(extendStay), controller.extendStay);

module.exports = router;
