const asyncHandler = require("../../utils/asyncHandler");
const pool = require("../../config/db");
const { processBatch, upsertByUuid } = require("../../services/sync.service");

// POST /api/sync/guests
const push = asyncHandler(async (req, res) => {
  const { records, device_id } = req.body;

  const results = await processBatch(pool, records, async (conn, r) => {
    const insertValues = {
      uuid: r.uuid,
      name: r.name,
      mobile: r.mobile,
      email: r.email || null,
      id_proof_type: r.id_proof_type || null,
      id_proof_number: r.id_proof_number || null,
      address: r.address || null,
      created_by_device: device_id,
    };
    const updateValues = {
      name: r.name,
      mobile: r.mobile,
      email: r.email || null,
      id_proof_type: r.id_proof_type || null,
      id_proof_number: r.id_proof_number || null,
      address: r.address || null,
    };
    return upsertByUuid(conn, "guests", r.uuid, insertValues, updateValues);
  });

  res.json({ results });
});

module.exports = { push };
