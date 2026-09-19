const createCrudController = require("./genericCrud.controller");
const paymentMethodModel = require("../models/paymentMethod.model");

module.exports = createCrudController(paymentMethodModel);
