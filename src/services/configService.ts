import { pool } from "../config/database"
import { logger } from "../utils/logger"

class ConfigService {
  // ✅ SEMUA KONFIGURASI TERSIMPAN DI DATABASE
  async saveConfig(key: string, value: string): Promise<boolean> {
    try {
      await pool.query(
        `INSERT INTO system_config (key, value, updated_at) 
         VALUES ($1, $2, CURRENT_TIMESTAMP) 
         ON CONFLICT (key) 
         DO UPDATE SET value = $2, updated_at = CURRENT_TIMESTAMP`,
        [key, value],
      )

      logger.info(`Configuration saved: ${key}`)
      return true
    } catch (error) {
      logger.error("Error saving config:", error)
      return false
    }
  }

  // ✅ LOAD KONFIGURASI DARI DATABASE
  async getConfig(key: string): Promise<string | null> {
    try {
      const result = await pool.query("SELECT value FROM system_config WHERE key = $1", [key])
      return result.rows.length > 0 ? result.rows[0].value : null
    } catch (error) {
      logger.error("Error getting config:", error)
      return null
    }
  }

  // ✅ LOAD SEMUA KONFIGURASI
  async getAllConfig(): Promise<Record<string, string>> {
    try {
      const result = await pool.query("SELECT key, value FROM system_config")
      const config: Record<string, string> = {}

      result.rows.forEach((row) => {
        config[row.key] = row.value
      })

      return config
    } catch (error) {
      logger.error("Error getting all config:", error)
      return {}
    }
  }
}

export const configService = new ConfigService()
