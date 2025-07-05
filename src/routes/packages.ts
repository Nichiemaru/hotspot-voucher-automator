import express from "express"
import { authenticateToken } from "../middleware/auth"
import { getMany } from "../db"
import { getMikrotikUserProfiles } from "../mikrotik"

const router = express.Router()

// Tambahkan endpoint untuk validasi profile MikroTik
router.post("/validate-profiles", authenticateToken, async (req, res) => {
  try {
    // Get all packages from database
    const packages = await getMany("SELECT profile FROM voucher_packages WHERE enabled = TRUE")

    // Get MikroTik profiles
    const mikrotikResult = await getMikrotikUserProfiles()

    if (!mikrotikResult.success) {
      return res.status(400).json({
        success: false,
        message: "Cannot connect to MikroTik",
      })
    }

    const mikrotikProfiles = mikrotikResult.data.map((p: any) => p.name)
    const missingProfiles: string[] = []

    // Check if all database profiles exist in MikroTik
    packages.forEach((pkg: any) => {
      if (!mikrotikProfiles.includes(pkg.profile)) {
        missingProfiles.push(pkg.profile)
      }
    })

    if (missingProfiles.length > 0) {
      return res.json({
        success: false,
        message: "Some profiles are missing in MikroTik",
        data: {
          missingProfiles,
          availableProfiles: mikrotikProfiles,
        },
      })
    }

    res.json({
      success: true,
      message: "All profiles are valid",
      data: {
        validProfiles: packages.map((p: any) => p.profile),
        mikrotikProfiles,
      },
    })
  } catch (error) {
    console.error("Validate profiles error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

export default router
