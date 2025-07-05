import express from "express"
import { authenticateToken } from "../middleware/auth"
import { mikrotikService } from "../services/mikrotikService"
import { logger } from "../utils/logger"

const router = express.Router()

// POST /api/mikrotik/test-connection
router.post("/test-connection", authenticateToken, async (req, res) => {
  try {
    const { host, username, password } = req.body

    if (!host || !username || !password) {
      return res.status(400).json({ error: "Host, username, and password required" })
    }

    // Test connection with provided credentials
    const testResult = await mikrotikService.testConnection(host, username, password)

    if (testResult.success) {
      res.json({ success: true, message: "Connection successful" })
    } else {
      res.status(400).json({ success: false, error: testResult.error })
    }
  } catch (error) {
    logger.error("MikroTik test connection error:", error)
    res.status(500).json({ error: "Connection test failed" })
  }
})

// GET /api/mikrotik/profiles
router.get("/profiles", authenticateToken, async (req, res) => {
  try {
    const profiles = await mikrotikService.getHotspotProfiles()
    res.json(profiles)
  } catch (error) {
    logger.error("Error fetching MikroTik profiles:", error)
    res.status(500).json({ error: "Failed to fetch profiles" })
  }
})

// GET /api/mikrotik/users
router.get("/users", authenticateToken, async (req, res) => {
  try {
    const users = await mikrotikService.getHotspotUsers()
    res.json(users)
  } catch (error) {
    logger.error("Error fetching MikroTik users:", error)
    res.status(500).json({ error: "Failed to fetch users" })
  }
})

// POST /api/mikrotik/create-user
router.post("/create-user", authenticateToken, async (req, res) => {
  try {
    const { username, password, profile } = req.body

    if (!username || !password || !profile) {
      return res.status(400).json({ error: "Username, password, and profile required" })
    }

    const result = await mikrotikService.createHotspotUser(username, password, profile)

    if (result) {
      res.json({ success: true, message: "User created successfully" })
    } else {
      res.status(400).json({ success: false, error: "Failed to create user" })
    }
  } catch (error) {
    logger.error("Error creating MikroTik user:", error)
    res.status(500).json({ error: "Failed to create user" })
  }
})

// DELETE /api/mikrotik/users/:username
router.delete("/users/:username", authenticateToken, async (req, res) => {
  try {
    const { username } = req.params

    const result = await mikrotikService.deleteHotspotUser(username)

    if (result) {
      res.json({ success: true, message: "User deleted successfully" })
    } else {
      res.status(404).json({ success: false, error: "User not found" })
    }
  } catch (error) {
    logger.error("Error deleting MikroTik user:", error)
    res.status(500).json({ error: "Failed to delete user" })
  }
})

export default router
