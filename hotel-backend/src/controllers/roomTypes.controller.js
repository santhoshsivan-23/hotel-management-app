const createCrudController = require("./genericCrud.controller");
const roomTypeModel = require("../models/roomType.model");

module.exports = createCrudController(roomTypeModel);
