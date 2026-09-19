const Joi = require("joi");

const create = Joi.object({
  name: Joi.string().max(150).required(),
  mobile: Joi.string().max(20).required(),
  email: Joi.string().email({ tlds: false }).allow("", null),
  id_proof_type: Joi.string().max(50).allow("", null),
  id_proof_number: Joi.string().max(100).allow("", null),
  address: Joi.string().allow("", null),
});

const update = create.fork(["name", "mobile"], (s) => s.optional());

module.exports = { create, update };
