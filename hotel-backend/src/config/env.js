require("dotenv").config();

function withFallback(name, fallback) {
  const value = process.env[name];
  if (value === undefined || value === "") {
    if (process.env.NODE_ENV === "production" && fallback === undefined) {
      throw new Error(`Missing required environment variable: ${name}`);
    }
    return fallback;
  }
  return value;
}

const env = {
  nodeEnv: process.env.NODE_ENV || "development",
  port: parseInt(process.env.PORT, 10) || 5000,

  db: {
    host: withFallback("DB_HOST", "localhost"),
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    user: withFallback("DB_USER", "root"),
    password: process.env.DB_PASSWORD || "",
    name: withFallback("DB_NAME", "hotel_db"),
    connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT, 10) || 10,
  },

  jwt: {
    secret: withFallback("JWT_SECRET", "dev_secret_change_me"),
    expiresIn: process.env.JWT_EXPIRES_IN || "8h",
    refreshSecret: withFallback("JWT_REFRESH_SECRET", "dev_refresh_secret_change_me"),
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "7d",
  },

  corsOrigin: process.env.CORS_ORIGIN || "*",
};

module.exports = env;
