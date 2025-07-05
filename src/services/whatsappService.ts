import axios from "axios"
import { configService } from "./configService"
import { logger } from "../utils/logger"
import { pool } from "../database" // Declare the pool variable

class WhatsAppService {
  // ✅ BENAR-BENAR KIRIM WHATSAPP OTOMATIS
  async sendVoucherMessage(
    phoneNumber: string,
    voucherData: {
      customerName: string
      packageName: string
      voucherCode: string
      voucherPassword: string
      duration: string
      speed: string
    },
  ): Promise<boolean> {
    try {
      // Load konfigurasi WhatsApp dari database
      const apiUrl = await configService.getConfig("whatsapp_api_url")
      const apiKey = await configService.getConfig("whatsapp_api_key")

      if (!apiUrl || !apiKey) {
        logger.warn("WhatsApp configuration incomplete")
        return false
      }

      // Format nomor telepon (hapus +, spasi, strip)
      const cleanPhone = phoneNumber.replace(/[+\s-]/g, "")

      // Format pesan voucher
      const message = `🎉 *VOUCHER WIFI BERHASIL DIBELI* 🎉

Halo *${voucherData.customerName}*!

Terima kasih telah melakukan pembelian. Berikut detail voucher WiFi Anda:

📦 *Paket:* ${voucherData.packageName}
⏱️ *Durasi:* ${voucherData.duration}
🚀 *Kecepatan:* ${voucherData.speed}

🔐 *DETAIL LOGIN:*
👤 *Username:* \`${voucherData.voucherCode}\`
🔑 *Password:* \`${voucherData.voucherPassword}\`

📋 *CARA MENGGUNAKAN:*
1. Hubungkan ke WiFi "Hotspot"
2. Buka browser, akan muncul halaman login
3. Masukkan username dan password di atas
4. Klik Login dan nikmati internet!

⚠️ *PENTING:*
- Voucher berlaku sesuai durasi yang dipilih
- Simpan username dan password dengan baik
- Hubungi kami jika ada kendala

Terima kasih telah mempercayai layanan kami! 🙏

---
*HotSpot Voucher System*
Powered by MikroTik RouterOS`

      // ✅ KIRIM KE WHATSAPP GATEWAY
      const response = await axios.post(
        `${apiUrl}/send-message`,
        {
          phone: cleanPhone,
          message: message,
          type: "text",
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
          },
          timeout: 15000,
        },
      )

      if (response.data.success || response.status === 200) {
        logger.info(`✅ WhatsApp voucher sent successfully to ${phoneNumber}`)

        // Log ke database untuk tracking
        await this.logWhatsAppActivity(phoneNumber, voucherData.voucherCode, "voucher_sent", "success")

        return true
      } else {
        logger.error("WhatsApp API error:", response.data)
        await this.logWhatsAppActivity(phoneNumber, voucherData.voucherCode, "voucher_sent", "failed")
        return false
      }
    } catch (error) {
      logger.error("Error sending WhatsApp voucher:", error)
      await this.logWhatsAppActivity(phoneNumber, "", "voucher_sent", "error")
      return false
    }
  }

  // ✅ LOG AKTIVITAS WHATSAPP
  private async logWhatsAppActivity(phone: string, voucherCode: string, action: string, status: string) {
    try {
      await pool.query(
        "INSERT INTO activity_logs (action, description, status, created_at) VALUES ($1, $2, $3, CURRENT_TIMESTAMP)",
        [action, `WhatsApp to ${phone} - Voucher: ${voucherCode}`, status],
      )
    } catch (error) {
      logger.error("Error logging WhatsApp activity:", error)
    }
  }

  // ✅ TEST WHATSAPP CONNECTION
  async testConnection(): Promise<boolean> {
    try {
      const apiUrl = await configService.getConfig("whatsapp_api_url")
      const apiKey = await configService.getConfig("whatsapp_api_key")

      if (!apiUrl || !apiKey) return false

      const response = await axios.get(`${apiUrl}/status`, {
        headers: { Authorization: `Bearer ${apiKey}` },
        timeout: 10000,
      })

      return response.status === 200
    } catch (error) {
      logger.error("WhatsApp connection test failed:", error)
      return false
    }
  }
}

export const whatsappService = new WhatsAppService()
