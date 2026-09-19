const express = require("express");
const router = express.Router();
const controller = require("../controllers/foodOrders.controller");
const validate = require("../middleware/validate.middleware");
const { create, updateStatus } = require("../validators/foodOrder.validator");
const authenticate = require("../middleware/auth.middleware");

router.use(authenticate);

router.get("/", controller.list);
router.get("/:id", controller.getById);
router.post("/", validate(create), controller.create);
router.patch("/:id/status", validate(updateStatus), controller.updateStatus);

module.exports = router;
