const Joi = require("joi");

const create = Joi.object({
  booking_id: Joi.number().integer().positive().required(),
  room_id: Joi.number().integer().positive().required(),
  guest_id: Joi.number().integer().positive().required(),
  service_type_id: Joi.number().integer().positive().required(),
  quantity: Joi.number().integer().min(1).default(1),
  notes: Joi.string().allow("", null),
});

const updateStatus = Joi.object({
  status: Joi.string()
    .valid("REQUESTED", "ACCEPTED", "IN_PROGRESS", "COMPLETED", "DELIVERED")
    .required(),
});

module.exports = { create, updateStatus };
