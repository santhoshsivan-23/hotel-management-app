/**
 * validate(schema) -> Express middleware that validates req.body against
 * a Joi schema. On failure, responds 400 with a readable message instead
 * of ever hitting the database with bad data.
 */
function validate(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      return res.status(400).json({
        message: "Validation failed",
        details: error.details.map((d) => d.message),
      });
    }

    req.body = value;
    next();
  };
}

module.exports = validate;
