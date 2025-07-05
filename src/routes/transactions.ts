import express from "express"
import { body, validationResult } from "express-validator"
import { getMany, executeQuery, getOne } from "../config/database"
import { authenticateToken } from "../middleware/auth"
import { createTriPayTransaction } from "../services/tripayService"
import { logger } from "../utils/logger"

const router = express.Router()

// Create new transaction
router.post(
  "/create",
  [
    body("packageId").isNumeric().withMessage("Package ID must be a number"),
    body("customerName").notEmpty().withMessage("Customer name is required"),
    body("customerEmail").isEmail().withMessage("Valid email is required"),
    body("customerPhone")
      .matches(/^(\+62|62|0)[0-9]{9,13}$/)
      .withMessage("Valid phone number is required"),
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

      const { packageId, customerName, customerEmail, customerPhone } = req.body

      // Get package details
      const voucherPackage = await getOne("SELECT * FROM voucher_packages WHERE id = ? AND enabled = TRUE", [packageId])

      if (!voucherPackage) {
        return res.status(404).json({
          success: false,
          message: "Package not found",
        })
      }

      // Generate merchant reference
      const merchantRef = `VOUCHER-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`

      // Create transaction in database
      const result = await executeQuery(
        "INSERT INTO transactions (merchant_ref, customer_name, customer_email, customer_phone, package_id, amount, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [merchantRef, customerName, customerEmail, customerPhone, packageId, voucherPackage.price, "pending"],
      )

      const transactionId = (result as any).insertId

      // Create TriPay transaction
      const tripayData = {
        method: "BRIVA",
        merchant_ref: merchantRef,
        amount: voucherPackage.price,
        customer_name: customerName,
        customer_email: customerEmail,
        customer_phone: customerPhone,
        order_items: [
          {
            sku: voucherPackage.profile,
            name: voucherPackage.name,
            price: voucherPackage.price,
            quantity: 1,
          },
        ],
        return_url: `${process.env.FRONTEND_URL}/payment-success`,
        expired_time: Math.floor(Date.now() / 1000) + 24 * 60 * 60,
      }

      const tripayResponse = await createTriPayTransaction(tripayData)

      if (tripayResponse.success) {
        // Update transaction with TriPay reference
        await executeQuery("UPDATE transactions SET reference = ?, tripay_data = ?, updated_at = NOW() WHERE id = ?", [
          tripayResponse.data.reference,
          JSON.stringify(tripayResponse.data),
          transactionId,
        ])

        // Log activity
        await executeQuery(
          "INSERT INTO activity_logs (transaction_id, action, description, status) VALUES (?, ?, ?, ?)",
          [transactionId, "CREATE_TRANSACTION", "Transaction created successfully", "success"],
        )

        res.json({
          success: true,
          message: "Transaction created successfully",
          data: {
            transaction_id: transactionId,
            reference: tripayResponse.data.reference,
            checkout_url: tripayResponse.data.checkout_url,
            amount: voucherPackage.price,
            package: voucherPackage,
          },
        })
      } else {
        // Update transaction status to failed
        await executeQuery("UPDATE transactions SET status = ?, updated_at = NOW() WHERE id = ?", [
          "failed",
          transactionId,
        ])

        res.status(400).json({
          success: false,
          message: tripayResponse.message || "Failed to create payment",
        })
      }
    } catch (error) {
      logger.error("Create transaction error:", error)
      res.status(500).json({
        success: false,
        message: "Internal server error",
      })
    }
  },
)

// Get transaction by reference
router.get("/:reference", async (req, res) => {
  try {
    const { reference } = req.params

    const transaction = await getOne(
      `
      SELECT t.*, p.name as package_name, p.profile, p.duration, p.speed
      FROM transactions t
      JOIN voucher_packages p ON t.package_id = p.id
      WHERE t.reference = ?
    `,
      [reference],
    )

    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: "Transaction not found",
      })
    }

    res.json({
      success: true,
      data: transaction,
    })
  } catch (error) {
    logger.error("Get transaction error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

// Get all transactions (admin)
router.get("/admin/list", authenticateToken, async (req, res) => {
  try {
    const page = Number.parseInt(req.query.page as string) || 1
    const limit = Number.parseInt(req.query.limit as string) || 10
    const offset = (page - 1) * limit

    const transactions = await getMany(
      `
      SELECT t.*, p.name as package_name
      FROM transactions t
      JOIN voucher_packages p ON t.package_id = p.id
      ORDER BY t.created_at DESC
      LIMIT ? OFFSET ?
    `,
      [limit, offset],
    )

    // Get total count
    const totalResult = await getOne("SELECT COUNT(*) as total FROM transactions")
    const total = totalResult.total

    res.json({
      success: true,
      data: {
        transactions,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    })
  } catch (error) {
    logger.error("Get transactions error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

export default router
