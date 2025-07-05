import { Router } from "express"
import { createMikrotikUser } from "../services/mikrotik"
import { executeQuery } from "../services/database"
import { sendWhatsAppVoucher } from "../services/whatsapp"

const router = Router()

router.post("/tripay", async (req, res) => {
  // 1. TriPay kirim webhook ke: https://yourdomain.com/api/webhooks/tripay
  // 2. Validasi signature webhook
  // 3. Update status transaksi di database
  // 4. Jika status = "PAID":

  const { status, transaction } = req.body

  if (status === "PAID") {
    try {
      // 5. Generate username & password voucher
      const username = `user_${Date.now()}`
      const password = Math.random().toString(36).substr(2, 8)

      // 6. Buat user di MikroTik otomatis
      const mikrotikResult = await createMikrotikUser({
        username,
        password,
        profile: transaction.profile, // sesuai paket yang dibeli
      })

      if (mikrotikResult.success) {
        // 7. Simpan voucher ke database
        await executeQuery(
          "UPDATE transactions SET voucher_username = ?, voucher_password = ?, voucher_created_at = NOW() WHERE id = ?",
          [username, password, transaction.id],
        )

        // 8. Kirim WhatsApp otomatis
        const whatsappResult = await sendWhatsAppVoucher(transaction.customer_phone, {
          username,
          password,
          package: transaction.package_name,
          duration: transaction.duration,
          customerName: transaction.customer_name,
        })

        // 9. Log semua aktivitas
        await executeQuery(
          "INSERT INTO activity_logs (transaction_id, action, description, status) VALUES (?, ?, ?, ?)",
          [transaction.id, "VOUCHER_CREATED", `Voucher created: ${username}`, "success"],
        )
      }
    } catch (error) {
      // Error handling lengkap
      console.error("Error processing TriPay webhook:", error)
      res.status(500).send("Internal Server Error")
    }
  } else {
    res.status(200).send("Webhook processed successfully")
  }
})

export default router
