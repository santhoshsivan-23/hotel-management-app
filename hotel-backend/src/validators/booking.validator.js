const Joi = require("joi");

const create = Joi.object({
  guest_id: Joi.number().integer().positive(),
  guest: Joi.object({
    name: Joi.string().max(150).required(),
    mobile: Joi.string().max(20).required(),
    email: Joi.string().email({ tlds: false }).allow("", null),
    id_proof_type: Joi.string().max(50).allow("", null),
    id_proof_number: Joi.string().max(100).allow("", null),
    address: Joi.string().allow("", null),
  }),
  room_id: Joi.number().integer().positive().required(),
  check_in: Joi.date().iso().required(),
  check_out: Joi.date().iso().greater(Joi.ref("check_in")).required(),
  adults: Joi.number().integer().min(1).default(1),
  children: Joi.number().integer().min(0).default(0),
  discount: Joi.number().min(0).default(0),
  advance_paid: Joi.number().min(0).default(0),
  payment_method: Joi.string().max(30).default("Cash"),
})
  .xor("guest_id", "guest")
  .messages({ "object.xor": "Provide either guest_id (existing guest) or guest (new guest details)" });

const updateStatus = Joi.object({
  status: Joi.string()
    .valid("PENDING", "CONFIRMED", "CHECKED_IN", "CHECKED_OUT", "CANCELLED", "NO_SHOW")
    .required(),
});

const changeRoom = Joi.object({
  room_id: Joi.number().integer().positive().required(),
});

const extendStay = Joi.object({
  check_out: Joi.date().iso().required(),
});

module.exports = { create, updateStatus, changeRoom, extendStay };
