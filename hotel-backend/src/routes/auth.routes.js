const express = require("express");
const router = express.Router();
const controller = require("../controllers/auth.controller");
const validate = require("../middleware/validate.middleware");
const { login } = require("../validators/auth.validator");
const authenticate = require("../middleware/auth.middleware");

router.post("/login", validate(login), controller.login);
router.post("/refresh", controller.refresh);
router.get("/me", authenticate, controller.me);

module.exports = router;
