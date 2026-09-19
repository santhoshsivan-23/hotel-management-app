const express = require("express");
const router = express.Router();
const controller = require("../controllers/maintenance.controller");
const authenticate = require("../middleware/auth.middleware");

router.use(authenticate);

router.get("/", controller.list);
router.post("/", controller.create);
router.patch("/:id/status", controller.updateStatus);

module.exports = router;
