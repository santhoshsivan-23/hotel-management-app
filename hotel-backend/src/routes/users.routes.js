const express = require("express");
const router = express.Router();
const controller = require("../controllers/users.controller");
const authenticate = require("../middleware/auth.middleware");
const requireRole = require("../middleware/role.middleware");
const { ROLES } = require("../config/constants");

router.use(authenticate, requireRole(ROLES.ADMIN));

router.get("/", controller.list);
router.post("/", controller.create);
router.patch("/:id/status", controller.updateStatus);

module.exports = router;
