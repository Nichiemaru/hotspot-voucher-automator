import express from "express"
import { body, validationResult } from "express-validator"
import { getMany, executeQuery, getOne } from "../config/database"
import { authenticateToken } from "../middleware/auth"

const router = express.Router()

// Get all configurations
router.get("/", authenticateToken, async (req, res) => {
  try {
    const configs = await getMany("SELECT key_name, value, description FROM configurations ORDER BY key_name")

    // Convert to object format
    const configObject: any = {}
    configs.forEach((config: any) => {
      configObject[config.key_name] = {
        value: config.value,
        description: config.description,
      }
    })

    res.json({
      success: true,
      data: configObject,
    })
  } catch (error) {
    console.error("Get configurations error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

// Update configuration
router.put(
  "/:key",
  authenticateToken,
  [body("value").notEmpty().withMessage("Value is required")],
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

      const { key } = req.params
      const { value } = req.body

      // Check if configuration exists
      const existingConfig = await getOne("SELECT id FROM configurations WHERE key_name = ?", [key])

      if (!existingConfig) {
        return res.status(404).json({
          success: false,
          message: "Configuration not found",
        })
      }

      // Update configuration
      await executeQuery("UPDATE configurations SET value = ?, updated_at = NOW() WHERE key_name = ?", [value, key])

      res.json({
        success: true,
        message: "Configuration updated successfully",
      })
    } catch (error) {
      console.error("Update configuration error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error",
      })
    }
  },
)

// Bulk update configurations
router.put("/", authenticateToken, async (req, res) => {
  try {
    const { configurations } = req.body

    if (!configurations || typeof configurations !== "object") {
      return res.status(400).json({
        success: false,
        message: "Configurations object is required",
      })
    }

    // Update each configuration
    for (const [key, value] of Object.entries(configurations)) {
      await executeQuery("UPDATE configurations SET value = ?, updated_at = NOW() WHERE key_name = ?", [value, key])
    }

    res.json({
      success: true,
      message: "Configurations updated successfully",
    })
  } catch (error) {
    console.error("Bulk update configurations error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

export default router
