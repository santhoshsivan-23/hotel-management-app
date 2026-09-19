const createCrudModel = require("./genericCrud.model");

module.exports = createCrudModel(
  "service_types",
  ["name", "category", "price", "tax_percent", "active"],
  "name ASC"
);
