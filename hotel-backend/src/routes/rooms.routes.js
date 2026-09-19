const express = require("express");
const router = express.Router();
const controller = require("../controllers/rooms.controller");
const validate = require("../middleware/validate.middleware");
const { create, update, updateStatus } = require("../validators/room.validator");
const authenticate = require("../middleware/auth.middleware");
const requireRole = require("../middleware/role.middleware");
const { ROLES } = require("../config/constants");

router.use(authenticate);

router.get("/available", controller.available);
router.get("/", controller.list);
router.get("/:id", controller.getById);
router.post("/", requireRole(ROLES.ADMIN, ROLES.MANAGER), validate(create), controller.create);
router.put("/:id", requireRole(ROLES.ADMIN, ROLES.MANAGER), validate(update), controller.update);
router.patch("/:id/status", validate(updateStatus), controller.updateStatus);
router.delete("/:id", requireRole(ROLES.ADMIN), controller.remove);

module.exports = router;
