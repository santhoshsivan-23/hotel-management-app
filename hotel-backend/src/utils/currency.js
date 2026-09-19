function formatCurrency(amount, currency = "INR") {
  const value = Number(amount) || 0;
  try {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency,
      maximumFractionDigits: 2,
    }).format(value);
  } catch (e) {
    return value.toFixed(2);
  }
}

function round2(amount) {
  return Math.round((Number(amount) + Number.EPSILON) * 100) / 100;
}

module.exports = { formatCurrency, round2 };
