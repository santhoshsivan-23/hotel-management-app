const express = require("express");
const router = express.Router();
const controller = require("../controllers/guests.controller");
const validate = require("../middleware/validate.middleware");
const { create, update } = require("../validators/guest.validator");
const authenticate = require("../middleware/auth.middleware");

router.use(authenticate);

router.get("/", controller.list);
router.get("/:id", controller.getById);
router.post("/", validate(create), controller.create);
router.put("/:id", validate(update), controller.update);
router.delete("/:id", controller.remove);

module.exports = router;
