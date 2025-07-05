import express from "express"
import { pool } from "../config/database"
import { authenticateToken } from "../middleware/auth"
import { logger } from "../utils/logger"

const router = express.Router()

// GET /api/config - Get all system configurations
router.get("/", authenticateToken, async (req, res) => {
  try {
    const result = await pool.query("SELECT key, value, description FROM system_config ORDER BY key")

    const config: Record<string, any> = {}
    result.rows.forEach((row) => {
      config[row.key] = {
        value: row.value,
        description: row.description,
      }
    })

    res.json(config)
  } catch (error) {
    logger.error("Error fetching config:", error)
    res.status(500).json({ error: "Failed to fetch configuration" })
  }
})

// PUT /api/config - Update system configuration
router.put("/", authenticateToken, async (req, res) => {
  try {
    const { configs } = req.body

    if (!configs || typeof configs !== "object") {
      return res.status(400).json({ error: "Invalid configuration data" })
    }

    // Update each configuration
    for (const [key, value] of Object.entries(configs)) {
      await pool.query(
        "INSERT INTO system_config (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = $2, updated_at = CURRENT_TIMESTAMP",
        [key, value],
      )
    }

    logger.info("System configuration updated")
    res.json({ success: true, message: "Configuration updated successfully" })
  } catch (error) {
    logger.error("Error updating config:", error)
    res.status(500).json({ error: "Failed to update configuration" })
  }
})

// GET /api/config/:key - Get specific configuration
router.get("/:key", async (req, res) => {
  try {
    const { key } = req.params
    const result = await pool.query("SELECT value FROM system_config WHERE key = $1", [key])

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Configuration not found" })
    }

    res.json({ value: result.rows[0].value })
  } catch (error) {
    logger.error("Error fetching config:", error)
    res.status(500).json({ error: "Failed to fetch configuration" })
  }
})

export default router
