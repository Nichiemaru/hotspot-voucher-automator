import express from "express"
import crypto from "crypto"
import { pool } from "../config/database"
import { logger } from "../utils/logger"
import { mikrotikService } from "../services/mikrotikService"
import { whatsappService } from "../services/whatsappService"
import { configService } from "../services/configService"

const router = express.Router()

// ✅ WEBHOOK TRIPAY - OTOMATIS PROSES PEMBAYARAN
router.post("/tripay", async (req, res) => {
  try {
    logger.info("🔔 TriPay webhook received:", req.body)

    // ✅ 1. VERIFIKASI SIGNATURE
    const callbackSignature = req.headers["x-callback-signature"] as string
    const payload = JSON.stringify(req.body)

    const privateKey = await configService.getConfig("tripay_private_key")
    if (!privateKey) {
      logger.error("❌ TriPay private key not configured")
      return res.status(500).json({ error: "Configuration error" })
    }

    const calculatedSignature = crypto.createHmac("sha256", privateKey).update(payload).digest("hex")

    if (calculatedSignature !== callbackSignature) {
      logger.error("❌ Invalid TriPay webhook signature")
      return res.status(400).json({ error: "Invalid signature" })
    }

    const { merchant_ref, status, paid_amount, payment_method, reference } = req.body

    logger.info(`📋 Processing payment: ${merchant_ref} - Status: ${status}`)

    // ✅ 2. GET TRANSACTION DATA
    const transactionResult = await pool.query(
      `SELECT t.*, vp.name as package_name, vp.profile, vp.duration, vp.speed, vp.price
       FROM transactions t 
       JOIN voucher_packages vp ON t.package_id = vp.id 
       WHERE t.id = $1`,
      [merchant_ref],
    )

    if (transactionResult.rows.length === 0) {
      logger.error(`❌ Transaction not found: ${merchant_ref}`)
      return res.status(404).json({ error: "Transaction not found" })
    }

    const transaction = transactionResult.rows[0]

    // ✅ 3. PROSES JIKA PEMBAYARAN BERHASIL
    if (status === "PAID") {
      logger.info(`💰 Payment successful for transaction: ${merchant_ref}`)

      try {
        // ✅ 4. GENERATE VOUCHER CREDENTIALS
        const voucherCode = mikrotikService.generateVoucherCode()
        const voucherPassword = mikrotikService.generateVoucherPassword()

        logger.info(`🎫 Generated voucher: ${voucherCode} / ${voucherPassword}`)

        // ✅ 5. CREATE USER DI MIKROTIK
        const userCreated = await mikrotikService.createHotspotUser(voucherCode, voucherPassword, transaction.profile)

        if (userCreated) {
          // ✅ 6. UPDATE TRANSACTION STATUS
          await pool.query(
            `UPDATE transactions 
             SET status = 'paid', voucher_code = $1, voucher_password = $2, 
                 payment_reference = $3, updated_at = CURRENT_TIMESTAMP 
             WHERE id = $4`,
            [voucherCode, voucherPassword, reference, merchant_ref],
          )

          // ✅ 7. KIRIM WHATSAPP OTOMATIS
          const whatsappSent = await whatsappService.sendVoucherMessage(transaction.customer_phone, {
            customerName: transaction.customer_name,
            packageName: transaction.package_name,
            voucherCode,
            voucherPassword,
            duration: transaction.duration,
            speed: transaction.speed,
          })

          // ✅ 8. LOG AKTIVITAS
          await pool.query(
            `INSERT INTO activity_logs (transaction_id, action, description, status, created_at) 
             VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)`,
            [
              merchant_ref,
              "voucher_created",
              `Voucher ${voucherCode} created and ${whatsappSent ? "sent" : "failed to send"} via WhatsApp`,
              whatsappSent ? "success" : "partial_success",
            ],
          )

          logger.info(`✅ Transaction completed successfully: ${merchant_ref}`)
          logger.info(`📱 WhatsApp sent: ${whatsappSent ? "YES" : "NO"}`)
        } else {
          // ✅ ERROR HANDLING
          await pool.query("UPDATE transactions SET status = 'paid_error' WHERE id = $1", [merchant_ref])

          logger.error(`❌ Failed to create MikroTik user for: ${merchant_ref}`)
        }
      } catch (error) {
        logger.error("❌ Error processing paid transaction:", error)

        await pool.query("UPDATE transactions SET status = 'paid_error' WHERE id = $1", [merchant_ref])
      }
    } else if (status === "EXPIRED" || status === "FAILED") {
      // ✅ 9. HANDLE FAILED/EXPIRED PAYMENTS
      await pool.query("UPDATE transactions SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", [
        status.toLowerCase(),
        merchant_ref,
      ])

      logger.info(`❌ Transaction ${status}: ${merchant_ref}`)
    }

    res.json({ success: true, message: "Webhook processed successfully" })
  } catch (error) {
    logger.error("❌ TriPay webhook error:", error)
    res.status(500).json({ error: "Webhook processing failed" })
  }
})

export default router
