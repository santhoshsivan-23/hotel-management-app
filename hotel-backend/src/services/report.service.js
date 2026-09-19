const pool = require("../config/db");

async function bookingReport({ fromDate, toDate } = {}) {
  const params = [];
  let sql = `
    SELECT b.booking_number, g.name AS guest, r.room_number, b.check_in, b.check_out,
           b.grand_total AS amount, b.status
    FROM bookings b
    JOIN guests g ON g.id = b.guest_id
    JOIN rooms r ON r.id = b.room_id
    WHERE 1 = 1
  `;
  if (fromDate) { sql += " AND b.check_in >= ?"; params.push(fromDate); }
  if (toDate) { sql += " AND b.check_out <= ?"; params.push(toDate); }
  sql += " ORDER BY b.check_in DESC";

  const [rows] = await pool.query(sql, params);
  return rows;
}

async function occupancyReport() {
  const [[totals]] = await pool.query(`
    SELECT
      COUNT(*) AS total_rooms,
      SUM(status = 'OCCUPIED') AS occupied,
      SUM(status = 'AVAILABLE') AS available,
      SUM(status = 'RESERVED') AS reserved,
      SUM(status = 'CLEANING' OR status = 'DIRTY') AS cleaning,
      SUM(status = 'MAINTENANCE' OR status = 'OUT_OF_SERVICE') AS maintenance
    FROM rooms
  `);
  const occupancyPercent = totals.total_rooms > 0
    ? Math.round((totals.occupied / totals.total_rooms) * 10000) / 100
    : 0;
  return { ...totals, occupancy_percent: occupancyPercent };
}

async function revenueReport({ fromDate, toDate } = {}) {
  const params = [fromDate || "1970-01-01", toDate || "2999-12-31"];

  const [[roomRevenue]] = await pool.query(
    `SELECT COALESCE(SUM(room_total), 0) AS total, COALESCE(SUM(discount), 0) AS discount,
            COALESCE(SUM(tax_amount), 0) AS tax
     FROM bookings WHERE check_in BETWEEN ? AND ? AND status != 'CANCELLED'`,
    params
  );
  const [[foodRevenue]] = await pool.query(
    `SELECT COALESCE(SUM(total_amount), 0) AS total FROM food_orders
     WHERE created_at BETWEEN ? AND ? AND status != 'CANCELLED'`,
    params
  );
  const [[serviceRevenue]] = await pool.query(
    `SELECT COALESCE(SUM(amount), 0) AS total FROM service_requests
     WHERE created_at BETWEEN ? AND ? AND status != 'CANCELLED'`,
    params
  );

  const roomRevenueTotal = Number(roomRevenue.total);
  const foodRevenueTotal = Number(foodRevenue.total);
  const serviceRevenueTotal = Number(serviceRevenue.total);
  const totalRevenue = roomRevenueTotal + foodRevenueTotal + serviceRevenueTotal;

  return {
    room_revenue: roomRevenueTotal,
    food_revenue: foodRevenueTotal,
    service_revenue: serviceRevenueTotal,
    other_revenue: 0,
    discount: Number(roomRevenue.discount),
    tax: Number(roomRevenue.tax),
    total_revenue: totalRevenue,
  };
}

async function foodSalesReport({ fromDate, toDate } = {}) {
  const params = [fromDate || "1970-01-01", toDate || "2999-12-31"];
  const [rows] = await pool.query(
    `SELECT fi.product_name AS product, SUM(fi.quantity) AS quantity,
            COUNT(DISTINCT fi.food_order_id) AS orders, SUM(fi.quantity * fi.price) AS revenue
     FROM food_order_items fi
     JOIN food_orders fo ON fo.id = fi.food_order_id
     WHERE fo.created_at BETWEEN ? AND ?
     GROUP BY fi.product_name
     ORDER BY revenue DESC`,
    params
  );
  return rows;
}

async function roomServicesReport({ fromDate, toDate } = {}) {
  const params = [fromDate || "1970-01-01", toDate || "2999-12-31"];
  const [rows] = await pool.query(
    `SELECT st.name AS service, SUM(sr.quantity) AS quantity, SUM(sr.amount) AS revenue
     FROM service_requests sr
     JOIN service_types st ON st.id = sr.service_type_id
     WHERE sr.created_at BETWEEN ? AND ?
     GROUP BY st.name
     ORDER BY revenue DESC`,
    params
  );
  return rows;
}

async function paymentReport({ fromDate, toDate } = {}) {
  const params = [fromDate || "1970-01-01", toDate || "2999-12-31"];
  const [rows] = await pool.query(
    `SELECT method AS payment_method, COUNT(*) AS transaction_count, SUM(amount) AS amount
     FROM payments WHERE paid_at BETWEEN ? AND ?
     GROUP BY method`,
    params
  );
  return rows;
}

async function outstandingReport() {
  const [rows] = await pool.query(`
    SELECT b.booking_number AS booking, g.name AS guest, r.room_number AS room,
           b.grand_total AS total, COALESCE(p.paid, 0) AS paid,
           b.grand_total - COALESCE(p.paid, 0) AS balance
    FROM bookings b
    JOIN guests g ON g.id = b.guest_id
    JOIN rooms r ON r.id = b.room_id
    LEFT JOIN (
      SELECT booking_id, SUM(amount) AS paid FROM payments GROUP BY booking_id
    ) p ON p.booking_id = b.id
    WHERE b.status != 'CANCELLED'
      AND (b.grand_total - COALESCE(p.paid, 0)) > 0
    ORDER BY balance DESC
  `);
  return rows;
}

module.exports = {
  bookingReport,
  occupancyReport,
  revenueReport,
  foodSalesReport,
  roomServicesReport,
  paymentReport,
  outstandingReport,
};
