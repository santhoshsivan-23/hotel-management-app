const Joi = require("joi");

const create = Joi.object({
  booking_id: Joi.number().integer().positive().required(),
  amount: Joi.number().positive().required(),
  method: Joi.string().max(30).required(),
  reference_no: Joi.string().max(100).allow("", null),
});

module.exports = { create };
