const createCrudController = require("./genericCrud.controller");
const serviceTypeModel = require("../models/serviceType.model");

module.exports = createCrudController(serviceTypeModel);
