const Joi = require("joi");

const create = Joi.object({
  room_number: Joi.string().max(20).required(),
  room_type_id: Joi.number().integer().positive().required(),
  floor: Joi.string().max(20).allow("", null),
  capacity: Joi.number().integer().min(1).required(),
  price: Joi.number().min(0).required(),
  amenity_ids: Joi.array().items(Joi.number().integer().positive()).default([]),
});

const update = create.fork(
  ["room_number", "room_type_id", "capacity", "price"],
  (s) => s.optional()
);

const updateStatus = Joi.object({
  status: Joi.string()
    .valid("AVAILABLE", "RESERVED", "OCCUPIED", "DIRTY", "CLEANING", "MAINTENANCE", "OUT_OF_SERVICE")
    .required(),
});

module.exports = { create, update, updateStatus };
