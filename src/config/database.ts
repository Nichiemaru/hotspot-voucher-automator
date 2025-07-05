import { Pool } from "pg"
import { logger } from "../utils/logger"

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === "production" ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
})

// Test database connection
pool.on("connect", () => {
  logger.info("Connected to PostgreSQL database")
})

pool.on("error", (err) => {
  logger.error("PostgreSQL connection error:", err)
})

export { pool }
export default pool
