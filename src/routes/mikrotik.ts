import express from "express"
import { body, validationResult } from "express-validator"
import { authenticateToken } from "../middleware/auth"
import { testMikrotikConnection, getMikrotikUsers } from "../services/mikrotikService"

const router = express.Router()

// Test MikroTik connection
router.post(
  "/test-connection",
  authenticateToken,
  [
    body("ipAddress").isIP().withMessage("Valid IP address is required"),
    body("username").notEmpty().withMessage("Username is required"),
    body("password").notEmpty().withMessage("Password is required"),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req)
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: "Validation error",
          errors: errors.array(),
        })
      }

      const { ipAddress, username, password } = req.body

      const result = await testMikrotikConnection({
        ipAddress,
        username,
        password,
      })

      res.json(result)
    } catch (error) {
      console.error("Test MikroTik connection error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error",
      })
    }
  },
)

// Get MikroTik users
router.get("/users", authenticateToken, async (req, res) => {
  try {
    const result = await getMikrotikUsers()
    res.json(result)
  } catch (error) {
    console.error("Get MikroTik users error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

export default router
