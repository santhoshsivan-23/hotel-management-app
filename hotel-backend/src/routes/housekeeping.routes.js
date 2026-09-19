const express = require("express");
const router = express.Router();
const controller = require("../controllers/housekeeping.controller");
const authenticate = require("../middleware/auth.middleware");

router.use(authenticate);

router.get("/", controller.list);
router.patch("/:id/status", controller.updateStatus);

module.exports = router;
