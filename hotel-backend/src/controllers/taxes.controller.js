const createCrudController = require("./genericCrud.controller");
const taxModel = require("../models/tax.model");

module.exports = createCrudController(taxModel);
