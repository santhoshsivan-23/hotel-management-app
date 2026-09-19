const createCrudModel = require("./genericCrud.model");

module.exports = createCrudModel(
  "taxes",
  ["name", "percentage", "applicable_to", "active"],
  "name ASC"
);
