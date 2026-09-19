const createCrudController = require("./genericCrud.controller");
const amenityModel = require("../models/amenity.model");

module.exports = createCrudController(amenityModel);
