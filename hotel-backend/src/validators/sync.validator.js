const Joi = require("joi");

// Generic envelope used by every /api/sync/* push endpoint.
// Each `records` entry must at least carry the client-generated `uuid` -
// that uuid is what makes the upsert idempotent server-side.
const pushBatch = Joi.object({
  device_id: Joi.string().max(100).required(),
  records: Joi.array()
    .items(
      Joi.object({
        uuid: Joi.string().guid({ version: "uuidv4" }).required(),
      }).unknown(true)
    )
    .min(1)
    .required(),
});

module.exports = { pushBatch };
