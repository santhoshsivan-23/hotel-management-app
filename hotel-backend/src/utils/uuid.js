const { v4: uuidv4, validate: isUuid } = require("uuid");

module.exports = {
  generateUuid: () => uuidv4(),
  isValidUuid: (value) => typeof value === "string" && isUuid(value),
};
