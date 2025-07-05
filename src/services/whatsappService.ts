import axios from "axios"
import { pool } from "../config/database"
import { logger } from "../utils/logger"

class WhatsAppService {
  private config: any = {}

  async loadConfig() {
    try {
      const result = await pool.query(`
        SELECT key, value FROM system_config 
        WHERE key IN ('whatsapp_api_url', 'whatsapp_api_key')
      `)

      this.config = {}
      result.rows.forEach((row) => {
        this.config[row.key] = row.value
      })
    } catch (error) {
      logger.error("Error loading WhatsApp config:", error)
      throw error
    }
  }

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
      await this.loadConfig()

      if (!this.config.whatsapp_api_url || !this.config.whatsapp_api_key) {
        logger.warn("WhatsApp configuration is incomplete, skipping message")
        return false
      }

      // Format phone number (remove + and spaces)
      const formattedPhone = phoneNumber.replace(/[+\s-]/g, "")

      const message = this.formatVoucherMessage(voucherData)

      const response = await axios.post(
        `${this.config.whatsapp_api_url}/send-message`,
        {
          phone: formattedPhone,
          message: message,
        },
        {
          headers: {
            Authorization: `Bearer ${this.config.whatsapp_api_key}`,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        },
      )

      if (response.data.success) {
        logger.info(`WhatsApp voucher sent to ${phoneNumber}`)
        return true
      } else {
        logger.error("WhatsApp API error:", response.data)
        return false
      }
    } catch (error) {
      logger.error("Error sending WhatsApp message:", error)
      return false
    }
  }

  private formatVoucherMessage(voucherData: {
    customerName: string
    packageName: string
    voucherCode: string
    voucherPassword: string
    duration: string
    speed: string
  }): string {
    return `🎉 *VOUCHER WIFI HOTSPOT* 🎉

Halo ${voucherData.customerName}!

Terima kasih telah melakukan pembelian. Berikut detail voucher WiFi Anda:

📦 *Paket:* ${voucherData.packageName}
⏱️ *Durasi:* ${voucherData.duration}
🚀 *Kecepatan:* ${voucherData.speed}

🔐 *DETAIL LOGIN:*
👤 Username: ${voucherData.voucherCode}
🔑 Password: ${voucherData.voucherPassword}

📋 *CARA MENGGUNAKAN:*
1. Hubungkan ke WiFi "Hotspot"
2. Buka browser, akan muncul halaman login
3. Masukkan username dan password di atas
4. Klik Login dan nikmati internet!

⚠️ *PENTING:*
- Voucher berlaku sesuai durasi yang dipilih
- Simpan username dan password dengan baik
- Hubungi kami jika ada kendala

Terima kasih! 🙏

---
*Hotspot Voucher System*`
  }

  async sendPaymentNotification(
    phoneNumber: string,
    customerName: string,
    amount: number,
    paymentUrl: string,
  ): Promise<boolean> {
    try {
      await this.loadConfig()

      if (!this.config.whatsapp_api_url || !this.config.whatsapp_api_key) {
        logger.warn("WhatsApp configuration is incomplete, skipping message")
        return false
      }

      const formattedPhone = phoneNumber.replace(/[+\s-]/g, "")
      const formattedAmount = new Intl.NumberFormat("id-ID", {
        style: "currency",
        currency: "IDR",
      }).format(amount)

      const message = `🔔 *KONFIRMASI PEMBAYARAN* 🔔

Halo ${customerName}!

Pesanan Anda telah dibuat dengan total pembayaran ${formattedAmount}.

Silakan lakukan pembayaran melalui link berikut:
${paymentUrl}

Voucher WiFi akan dikirim otomatis setelah pembayaran berhasil.

Terima kasih! 🙏

---
*Hotspot Voucher System*`

      const response = await axios.post(
        `${this.config.whatsapp_api_url}/send-message`,
        {
          phone: formattedPhone,
          message: message,
        },
        {
          headers: {
            Authorization: `Bearer ${this.config.whatsapp_api_key}`,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        },
      )

      if (response.data.success) {
        logger.info(`WhatsApp payment notification sent to ${phoneNumber}`)
        return true
      } else {
        logger.error("WhatsApp API error:", response.data)
        return false
      }
    } catch (error) {
      logger.error("Error sending WhatsApp payment notification:", error)
      return false
    }
  }
}

export const whatsappService = new WhatsAppService()
