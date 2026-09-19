const asyncHandler = require("../utils/asyncHandler");

/**
 * Factory that produces list/getById/create/update/remove handlers for a
 * simple reference-data model built with models/genericCrud.model.js.
 */
function createCrudController(model) {
  return {
    list: asyncHandler(async (req, res) => {
      const activeOnly = req.query.active === "true";
      const rows = await model.findAll({ activeOnly });
      res.json(rows);
    }),

    getById: asyncHandler(async (req, res) => {
      const row = await model.findById(req.params.id);
      if (!row) return res.status(404).json({ message: "Not found" });
      res.json(row);
    }),

    create: asyncHandler(async (req, res) => {
      const row = await model.create(req.body);
      res.status(201).json(row);
    }),

    update: asyncHandler(async (req, res) => {
      const row = await model.update(req.params.id, req.body);
      if (!row) return res.status(404).json({ message: "Not found" });
      res.json(row);
    }),

    remove: asyncHandler(async (req, res) => {
      const ok = await model.remove(req.params.id);
      if (!ok) return res.status(404).json({ message: "Not found" });
      res.status(204).send();
    }),
  };
}

module.exports = createCrudController;
