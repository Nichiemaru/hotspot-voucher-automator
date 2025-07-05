import express from "express"
import bcrypt from "bcrypt"
import { pool } from "../config/database"
import { generateToken } from "../middleware/auth"
import { logger } from "../utils/logger"

const router = express.Router()

// POST /api/auth/login
router.post("/login", async (req, res) => {
  try {
    const { username, password } = req.body

    if (!username || !password) {
      return res.status(400).json({ error: "Username and password required" })
    }

    // Get admin user from database
    const result = await pool.query("SELECT * FROM admin_users WHERE username = $1", [username])

    if (result.rows.length === 0) {
      return res.status(401).json({ error: "Invalid credentials" })
    }

    const admin = result.rows[0]

    // Check password
    const validPassword = await bcrypt.compare(password, admin.password_hash)

    if (!validPassword) {
      return res.status(401).json({ error: "Invalid credentials" })
    }

    // Generate JWT token
    const token = generateToken({
      id: admin.id,
      username: admin.username,
      role: "admin",
    })

    // Update last login
    await pool.query("UPDATE admin_users SET last_login = CURRENT_TIMESTAMP WHERE id = $1", [admin.id])

    logger.info(`Admin login: ${username}`)

    res.json({
      success: true,
      token,
      user: {
        id: admin.id,
        username: admin.username,
        created_at: admin.created_at,
      },
    })
  } catch (error) {
    logger.error("Login error:", error)
    res.status(500).json({ error: "Login failed" })
  }
})

// POST /api/auth/change-password
router.post("/change-password", async (req, res) => {
  try {
    const { currentPassword, newPassword, username } = req.body

    if (!currentPassword || !newPassword || !username) {
      return res.status(400).json({ error: "All fields required" })
    }

    // Get admin user
    const result = await pool.query("SELECT * FROM admin_users WHERE username = $1", [username])

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" })
    }

    const admin = result.rows[0]

    // Verify current password
    const validPassword = await bcrypt.compare(currentPassword, admin.password_hash)

    if (!validPassword) {
      return res.status(401).json({ error: "Current password is incorrect" })
    }

    // Hash new password
    const saltRounds = 10
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds)

    // Update password
    await pool.query("UPDATE admin_users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", [
      newPasswordHash,
      admin.id,
    ])

    logger.info(`Password changed for admin: ${username}`)

    res.json({ success: true, message: "Password changed successfully" })
  } catch (error) {
    logger.error("Change password error:", error)
    res.status(500).json({ error: "Failed to change password" })
  }
})

export default router
