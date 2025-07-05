import express from "express"
import { Pool } from "pg"
import { authenticateToken } from "../middleware/auth"
import { logger } from "../utils/logger"
import { mikrotikService } from "../services/mikrotikService"

const router = express.Router()
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
})

// GET /api/packages - Get all active packages
router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM voucher_packages WHERE enabled = true ORDER BY price ASC")
    res.json(result.rows)
  } catch (error) {
    logger.error("Error fetching packages:", error)
    res.status(500).json({ error: "Failed to fetch packages" })
  }
})

// GET /api/packages/admin - Get all packages (admin only)
router.get("/admin", authenticateToken, async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM voucher_packages ORDER BY created_at DESC")
    res.json(result.rows)
  } catch (error) {
    logger.error("Error fetching admin packages:", error)
    res.status(500).json({ error: "Failed to fetch packages" })
  }
})

// POST /api/packages - Create new package (admin only)
router.post("/", authenticateToken, async (req, res) => {
  try {
    const { name, profile, price, duration, speed, description } = req.body

    // Validate MikroTik profile exists
    const profileExists = await mikrotikService.checkProfile(profile)
    if (!profileExists) {
      return res.status(400).json({
        error: `MikroTik profile '${profile}' does not exist`,
      })
    }

    const result = await pool.query(
      `INSERT INTO voucher_packages (name, profile, price, duration, speed, description, enabled) 
       VALUES ($1, $2, $3, $4, $5, $6, true) 
       RETURNING *`,
      [name, profile, price, duration, speed, description],
    )

    logger.info(`Package created: ${name}`)
    res.status(201).json(result.rows[0])
  } catch (error) {
    logger.error("Error creating package:", error)
    res.status(500).json({ error: "Failed to create package" })
  }
})

// PUT /api/packages/:id - Update package (admin only)
router.put("/:id", authenticateToken, async (req, res) => {
  try {
    const { id } = req.params
    const { name, profile, price, duration, speed, description, enabled } = req.body

    // Validate MikroTik profile exists if profile is being updated
    if (profile) {
      const profileExists = await mikrotikService.checkProfile(profile)
      if (!profileExists) {
        return res.status(400).json({
          error: `MikroTik profile '${profile}' does not exist`,
        })
      }
    }

    const result = await pool.query(
      `UPDATE voucher_packages 
       SET name = $1, profile = $2, price = $3, duration = $4, speed = $5, 
           description = $6, enabled = $7, updated_at = CURRENT_TIMESTAMP
       WHERE id = $8 
       RETURNING *`,
      [name, profile, price, duration, speed, description, enabled, id],
    )

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Package not found" })
    }

    logger.info(`Package updated: ${name}`)
    res.json(result.rows[0])
  } catch (error) {
    logger.error("Error updating package:", error)
    res.status(500).json({ error: "Failed to update package" })
  }
})

// DELETE /api/packages/:id - Delete package (admin only)
router.delete("/:id", authenticateToken, async (req, res) => {
  try {
    const { id } = req.params

    const result = await pool.query("DELETE FROM voucher_packages WHERE id = $1 RETURNING *", [id])

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Package not found" })
    }

    logger.info(`Package deleted: ${result.rows[0].name}`)
    res.json({ message: "Package deleted successfully" })
  } catch (error) {
    logger.error("Error deleting package:", error)
    res.status(500).json({ error: "Failed to delete package" })
  }
})

export default router
