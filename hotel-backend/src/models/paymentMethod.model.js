const createCrudModel = require("./genericCrud.model");

module.exports = createCrudModel("payment_methods", ["name", "active"], "name ASC");
