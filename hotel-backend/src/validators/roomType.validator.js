const Joi = require("joi");

const create = Joi.object({
  name: Joi.string().max(100).required(),
  description: Joi.string().allow("", null),
  default_capacity: Joi.number().integer().min(1).default(2),
  default_price: Joi.number().min(0).required(),
  active: Joi.boolean().default(true),
});

const update = create.fork(["name", "default_price"], (s) => s.optional());

module.exports = { create, update };
