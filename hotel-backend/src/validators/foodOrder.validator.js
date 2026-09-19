const Joi = require("joi");

const item = Joi.object({
  product_name: Joi.string().max(150).required(),
  quantity: Joi.number().integer().min(1).required(),
  price: Joi.number().min(0).required(),
  modifiers: Joi.string().allow("", null),
  notes: Joi.string().allow("", null),
});

const create = Joi.object({
  booking_id: Joi.number().integer().positive().required(),
  room_id: Joi.number().integer().positive().required(),
  guest_id: Joi.number().integer().positive().required(),
  items: Joi.array().items(item).min(1).required(),
});

const updateStatus = Joi.object({
  status: Joi.string()
    .valid("NEW", "ACCEPTED", "PREPARING", "READY", "DELIVERED", "COMPLETED")
    .required(),
});

module.exports = { create, updateStatus };
