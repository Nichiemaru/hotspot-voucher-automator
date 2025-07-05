import express from "express"
import crypto from "crypto"
import { Pool } from "pg"
import { logger } from "../utils/logger"
import { mikrotikService } from "../services/mikrotikService"
import { whatsappService } from "../services/whatsappService"

const router = express.Router()
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
})

// TriPay webhook handler
router.post("/tripay", async (req, res) => {
  try {
    const callbackSignature = req.headers["x-callback-signature"] as string
    const payload = JSON.stringify(req.body)

    // Get TriPay private key from database
    const configResult = await pool.query("SELECT value FROM system_config WHERE key = 'tripay_private_key'")

    if (configResult.rows.length === 0) {
      logger.error("TriPay private key not configured")
      return res.status(500).json({ error: "Configuration error" })
    }

    const privateKey = configResult.rows[0].value

    // Verify signature
    const calculatedSignature = crypto.createHmac("sha256", privateKey).update(payload).digest("hex")

    if (calculatedSignature !== callbackSignature) {
      logger.error("Invalid TriPay webhook signature")
      return res.status(400).json({ error: "Invalid signature" })
    }

    const { merchant_ref, status, paid_amount, payment_method } = req.body

    logger.info(`TriPay webhook received: ${merchant_ref} - ${status}`)

    // Get transaction details
    const transactionResult = await pool.query(
      `SELECT t.*, vp.name as package_name, vp.profile, vp.duration, vp.speed 
       FROM transactions t 
       JOIN voucher_packages vp ON t.package_id = vp.id 
       WHERE t.id = $1`,
      [merchant_ref],
    )

    if (transactionResult.rows.length === 0) {
      logger.error(`Transaction not found: ${merchant_ref}`)
      return res.status(404).json({ error: "Transaction not found" })
    }

    const transaction = transactionResult.rows[0]

    if (status === "PAID") {
      // Update transaction status
      await pool.query("UPDATE transactions SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", [
        "paid",
        merchant_ref,
      ])

      // Generate voucher credentials
      const voucherCode = mikrotikService.generateVoucherCode()
      const voucherPassword = mikrotikService.generateVoucherPassword()

      // Create MikroTik user
      try {
        const userCreated = await mikrotikService.createHotspotUser(voucherCode, voucherPassword, transaction.profile)

        if (userCreated) {
          // Update transaction with voucher details
          await pool.query("UPDATE transactions SET voucher_code = $1, voucher_password = $2 WHERE id = $3", [
            voucherCode,
            voucherPassword,
            merchant_ref,
          ])

          // Send WhatsApp notification
          await whatsappService.sendVoucherMessage(transaction.customer_phone, {
            customerName: transaction.customer_name,
            packageName: transaction.package_name,
            voucherCode,
            voucherPassword,
            duration: transaction.duration,
            speed: transaction.speed,
          })

          logger.info(`Voucher created and sent for transaction: ${merchant_ref}`)
        } else {
          logger.error(`Failed to create MikroTik user for transaction: ${merchant_ref}`)

          // Update transaction status to indicate error
          await pool.query("UPDATE transactions SET status = $1 WHERE id = $2", ["paid_error", merchant_ref])
        }
      } catch (error) {
        logger.error("Error processing paid transaction:", error)

        // Update transaction status to indicate error
        await pool.query("UPDATE transactions SET status = $1 WHERE id = $2", ["paid_error", merchant_ref])
      }
    } else if (status === "EXPIRED" || status === "FAILED") {
      // Update transaction status
      await pool.query("UPDATE transactions SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", [
        status.toLowerCase(),
        merchant_ref,
      ])

      logger.info(`Transaction ${status.toLowerCase()}: ${merchant_ref}`)
    }

    res.json({ success: true })
  } catch (error) {
    logger.error("TriPay webhook error:", error)
    res.status(500).json({ error: "Webhook processing failed" })
  }
})

// Test webhook endpoint
router.post("/test", async (req, res) => {
  try {
    logger.info("Test webhook received:", req.body)
    res.json({ success: true, message: "Test webhook received" })
  } catch (error) {
    logger.error("Test webhook error:", error)
    res.status(500).json({ error: "Test webhook failed" })
  }
})

export default router
