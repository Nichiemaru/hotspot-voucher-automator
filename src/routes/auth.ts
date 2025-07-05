import express from "express"
import bcrypt from "bcrypt"
import jwt from "jsonwebtoken"
import { body, validationResult } from "express-validator"
import { getOne, executeQuery } from "../config/database"
import { authenticateToken } from "../middleware/auth"

const router = express.Router()

// Login endpoint
router.post(
  "/login",
  [
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

      const { username, password } = req.body

      // Get user from database
      const user = await getOne("SELECT id, username, password_hash, email FROM admin_users WHERE username = ?", [
        username,
      ])

      if (!user) {
        return res.status(401).json({
          success: false,
          message: "Invalid credentials",
        })
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash)
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: "Invalid credentials",
        })
      }

      // Update last login
      await executeQuery("UPDATE admin_users SET last_login = NOW() WHERE id = ?", [user.id])

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, username: user.username },
        process.env.JWT_SECRET || "your-secret-key",
        { expiresIn: "24h" },
      )

      res.json({
        success: true,
        message: "Login successful",
        data: {
          token,
          user: {
            id: user.id,
            username: user.username,
            email: user.email,
          },
        },
      })
    } catch (error) {
      console.error("Login error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error",
      })
    }
  },
)

// Change password endpoint
router.post(
  "/change-password",
  authenticateToken,
  [
    body("currentPassword").notEmpty().withMessage("Current password is required"),
    body("newPassword").isLength({ min: 6 }).withMessage("New password must be at least 6 characters"),
    body("confirmPassword").custom((value, { req }) => {
      if (value !== req.body.newPassword) {
        throw new Error("Password confirmation does not match")
      }
      return true
    }),
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

      const { currentPassword, newPassword } = req.body
      const userId = (req as any).user.id

      // Get current user
      const user = await getOne("SELECT password_hash FROM admin_users WHERE id = ?", [userId])

      // Verify current password
      const isValidPassword = await bcrypt.compare(currentPassword, user.password_hash)
      if (!isValidPassword) {
        return res.status(400).json({
          success: false,
          message: "Current password is incorrect",
        })
      }

      // Hash new password
      const saltRounds = 10
      const newPasswordHash = await bcrypt.hash(newPassword, saltRounds)

      // Update password
      await executeQuery("UPDATE admin_users SET password_hash = ?, updated_at = NOW() WHERE id = ?", [
        newPasswordHash,
        userId,
      ])

      res.json({
        success: true,
        message: "Password changed successfully",
      })
    } catch (error) {
      console.error("Change password error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error",
      })
    }
  },
)

// Verify token endpoint
router.get("/verify", authenticateToken, (req, res) => {
  res.json({
    success: true,
    message: "Token is valid",
    user: (req as any).user,
  })
})

export default router
