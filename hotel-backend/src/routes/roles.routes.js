const express = require("express");
const router = express.Router();
const controller = require("../controllers/roles.controller");
const authenticate = require("../middleware/auth.middleware");

router.use(authenticate);

router.get("/", controller.list);

module.exports = router;
