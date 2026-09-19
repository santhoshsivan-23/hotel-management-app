const express = require("express");
const router = express.Router();
const controller = require("../../controllers/sync/syncFoodOrders.controller");
const validate = require("../../middleware/validate.middleware");
const { pushBatch } = require("../../validators/sync.validator");

router.post("/", validate(pushBatch), controller.push);

module.exports = router;
