import mysql from "mysql2/promise"
import { logger } from "../utils/logger"

interface DatabaseConfig {
  host: string
  user: string
  password: string
  database: string
  port: number
  connectionLimit: number
}

const config: DatabaseConfig = {
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "hotspot_voucher",
  port: Number.parseInt(process.env.DB_PORT || "3306"),
  connectionLimit: 10,
}

// Create connection pool
export const pool = mysql.createPool(config)

// Test database connection
export const testConnection = async (): Promise<boolean> => {
  try {
    const connection = await pool.getConnection()
    await connection.ping()
    connection.release()
    logger.info("Database connection successful")
    return true
  } catch (error) {
    logger.error("Database connection failed:", error)
    return false
  }
}

// Execute query with error handling
export const executeQuery = async (query: string, params: any[] = []): Promise<any> => {
  try {
    const [results] = await pool.execute(query, params)
    return results
  } catch (error) {
    logger.error("Database query error:", { query, params, error })
    throw error
  }
}

// Get single row
export const getOne = async (query: string, params: any[] = []): Promise<any> => {
  const results = await executeQuery(query, params)
  return Array.isArray(results) && results.length > 0 ? results[0] : null
}

// Get multiple rows
export const getMany = async (query: string, params: any[] = []): Promise<any[]> => {
  const results = await executeQuery(query, params)
  return Array.isArray(results) ? results : []
}
