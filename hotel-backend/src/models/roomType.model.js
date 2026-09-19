const createCrudModel = require("./genericCrud.model");

module.exports = createCrudModel(
  "room_types",
  ["name", "description", "default_capacity", "default_price", "active"],
  "name ASC"
);
