const createCrudModel = require("./genericCrud.model");

module.exports = createCrudModel("amenities", ["name", "active"], "name ASC");
