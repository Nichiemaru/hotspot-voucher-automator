import axios from "axios"
import { getOne } from "../config/database"
import { logger } from "../utils/logger"

interface WhatsAppConfig {
  endpoint: string
  apiKey: string
}

interface VoucherData {
  username: string
  password: string
  package: string
  duration: string
  customerName: string
}

class WhatsAppService {
  private async getConfig(): Promise<WhatsAppConfig | null> {
    try {
      const endpointConfig = await getOne("SELECT value FROM configurations WHERE key_name = ?", ["whatsapp_endpoint"])
      const apiKeyConfig = await getOne("SELECT value FROM configurations WHERE key_name = ?", ["whatsapp_api_key"])

      if (!endpointConfig?.value || !apiKeyConfig?.value) {
        return null
      }

      return {
        endpoint: endpointConfig.value,
        apiKey: apiKeyConfig.value,
      }
    } catch (error) {
      logger.error("Error getting WhatsApp config:", error)
      return null
    }
  }

  private formatPhoneNumber(phone: string): string {
    // Remove all non-numeric characters
    let cleanPhone = phone.replace(/\D/g, "")

    // Convert to international format
    if (cleanPhone.startsWith("0")) {
      cleanPhone = "62" + cleanPhone.substring(1)
    } else if (cleanPhone.startsWith("8")) {
      cleanPhone = "62" + cleanPhone
    } else if (!cleanPhone.startsWith("62")) {
      cleanPhone = "62" + cleanPhone
    }

    return cleanPhone
  }

  private generateVoucherMessage(data: VoucherData): string {
    return `🎉 *Voucher Internet Berhasil Dibeli!*

Halo ${data.customerName},

Terima kasih telah membeli voucher internet kami. Berikut detail voucher Anda:

📦 *Paket:* ${data.package}
⏰ *Durasi:* ${data.duration}
👤 *Username:* ${data.username}
🔐 *Password:* ${data.password}

📋 *Cara Login:*
1. Buka browser di perangkat Anda
2. Ketik alamat: 192.168.1.1
3. Masukkan username dan password di atas
4. Klik Login dan nikmati internet cepat!

⚠️ *Penting:*
- Simpan username dan password dengan baik
- Voucher berlaku sesuai durasi yang dipilih
- Jika ada kendala, hubungi customer service

Terima kasih telah menggunakan layanan kami! 🙏

---
*HotSpot Voucher*
Internet Cepat & Terpercaya`
  }

  async sendVoucher(phone: string, voucherData: VoucherData) {
    try {
      const config = await this.getConfig()

      if (!config) {
        return {
          success: false,
          message: "WhatsApp configuration not found",
        }
      }

      const formattedPhone = this.formatPhoneNumber(phone)
      const message = this.generateVoucherMessage(voucherData)

      // Example for generic WhatsApp Gateway API
      const response = await axios.post(
        config.endpoint,
        {
          to: formattedPhone,
          message: message,
          type: "text",
        },
        {
          headers: {
            Authorization: `Bearer ${config.apiKey}`,
            "Content-Type": "application/json",
          },
          timeout: 30000,
        },
      )

      logger.info("WhatsApp voucher sent:", {
        phone: formattedPhone,
        username: voucherData.username,
      })

      return {
        success: true,
        message: "WhatsApp sent successfully",
        data: response.data,
      }
    } catch (error: any) {
      logger.error("WhatsApp send error:", error.response?.data || error.message)

      return {
        success: false,
        message: `Failed to send WhatsApp: ${error.response?.data?.message || error.message}`,
      }
    }
  }

  // Alternative method for Fonnte.com (popular Indonesian WhatsApp Gateway)
  async sendVoucherFonnte(phone: string, voucherData: VoucherData) {
    try {
      const config = await this.getConfig()

      if (!config) {
        return {
          success: false,
          message: "WhatsApp configuration not found",
        }
      }

      const formattedPhone = this.formatPhoneNumber(phone)
      const message = this.generateVoucherMessage(voucherData)

      const response = await axios.post(
        "https://api.fonnte.com/send",
        {
          target: formattedPhone,
          message: message,
          countryCode: "62",
        },
        {
          headers: {
            Authorization: config.apiKey,
            "Content-Type": "application/json",
          },
          timeout: 30000,
        },
      )

      logger.info("WhatsApp voucher sent via Fonnte:", {
        phone: formattedPhone,
        username: voucherData.username,
      })

      return {
        success: true,
        message: "WhatsApp sent successfully via Fonnte",
        data: response.data,
      }
    } catch (error: any) {
      logger.error("WhatsApp Fonnte send error:", error.response?.data || error.message)

      return {
        success: false,
        message: `Failed to send WhatsApp via Fonnte: ${error.response?.data?.message || error.message}`,
      }
    }
  }

  // Method for Twilio WhatsApp API
  async sendVoucherTwilio(phone: string, voucherData: VoucherData) {
    try {
      const twilioAccountSid = process.env.TWILIO_ACCOUNT_SID
      const twilioAuthToken = process.env.TWILIO_AUTH_TOKEN
      const twilioWhatsAppNumber = process.env.TWILIO_WHATSAPP_NUMBER

      if (!twilioAccountSid || !twilioAuthToken || !twilioWhatsAppNumber) {
        return {
          success: false,
          message: "Twilio configuration not found",
        }
      }

      const formattedPhone = this.formatPhoneNumber(phone)
      const message = this.generateVoucherMessage(voucherData)

      const response = await axios.post(
        `https://api.twilio.com/2010-04-01/Accounts/${twilioAccountSid}/Messages.json`,
        new URLSearchParams({
          From: `whatsapp:${twilioWhatsAppNumber}`,
          To: `whatsapp:+${formattedPhone}`,
          Body: message,
        }),
        {
          auth: {
            username: twilioAccountSid,
            password: twilioAuthToken,
          },
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          timeout: 30000,
        },
      )

      logger.info("WhatsApp voucher sent via Twilio:", {
        phone: formattedPhone,
        username: voucherData.username,
      })

      return {
        success: true,
        message: "WhatsApp sent successfully via Twilio",
        data: response.data,
      }
    } catch (error: any) {
      logger.error("WhatsApp Twilio send error:", error.response?.data || error.message)

      return {
        success: false,
        message: `Failed to send WhatsApp via Twilio: ${error.response?.data?.message || error.message}`,
      }
    }
  }
}

const whatsappService = new WhatsAppService()

export const sendWhatsAppVoucher = (phone: string, voucherData: VoucherData) =>
  whatsappService.sendVoucher(phone, voucherData)

export const sendWhatsAppVoucherFonnte = (phone: string, voucherData: VoucherData) =>
  whatsappService.sendVoucherFonnte(phone, voucherData)

export const sendWhatsAppVoucherTwilio = (phone: string, voucherData: VoucherData) =>
  whatsappService.sendVoucherTwilio(phone, voucherData)
