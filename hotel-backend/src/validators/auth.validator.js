const Joi = require("joi");

const login = Joi.object({
  username: Joi.string().required(),
  password: Joi.string().required(),
});

module.exports = { login };
