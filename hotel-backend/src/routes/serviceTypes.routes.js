const express = require("express");
const router = express.Router();
const controller = require("../controllers/serviceTypes.controller");
const authenticate = require("../middleware/auth.middleware");
const requireRole = require("../middleware/role.middleware");
const { ROLES } = require("../config/constants");

router.use(authenticate);

router.get("/", controller.list);
router.get("/:id", controller.getById);
router.post("/", requireRole(ROLES.ADMIN, ROLES.MANAGER), controller.create);
router.put("/:id", requireRole(ROLES.ADMIN, ROLES.MANAGER), controller.update);
router.delete("/:id", requireRole(ROLES.ADMIN), controller.remove);

module.exports = router;
