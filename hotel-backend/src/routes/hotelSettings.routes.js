const express = require("express");
const router = express.Router();
const controller = require("../controllers/hotelSettings.controller");
const authenticate = require("../middleware/auth.middleware");
const requireRole = require("../middleware/role.middleware");
const { ROLES } = require("../config/constants");

router.use(authenticate);

router.get("/", controller.get);
router.put("/", requireRole(ROLES.ADMIN), controller.update);

module.exports = router;
