import axios from "axios"
import crypto from "crypto"
import { pool } from "../config/database"
import { logger } from "../utils/logger"

class TriPayService {
  private config: any = {}

  async loadConfig() {
    try {
      const result = await pool.query(`
        SELECT key, value FROM system_config 
        WHERE key IN ('tripay_merchant_code', 'tripay_api_key', 'tripay_private_key', 'tripay_mode')
      `)

      this.config = {}
      result.rows.forEach((row) => {
        this.config[row.key] = row.value
      })
    } catch (error) {
      logger.error("Error loading TriPay config:", error)
      throw error
    }
  }

  private getBaseUrl(): string {
    return this.config.tripay_mode === "production" ? "https://tripay.co.id/api" : "https://tripay.co.id/api-sandbox"
  }

  private generateSignature(data: string): string {
    return crypto.createHmac("sha256", this.config.tripay_private_key).update(data).digest("hex")
  }

  async getPaymentChannels(): Promise<any[]> {
    try {
      await this.loadConfig()

      const response = await axios.get(`${this.getBaseUrl()}/merchant/payment-channel`, {
        headers: {
          Authorization: `Bearer ${this.config.tripay_api_key}`,
        },
      })

      return response.data.data
    } catch (error) {
      logger.error("Error getting payment channels:", error)
      throw error
    }
  }

  async createPayment(paymentData: {
    merchant_ref: string
    amount: number
    customer_name: string
    customer_email?: string
    customer_phone: string
    order_items: Array<{
      name: string
      price: number
      quantity: number
    }>
    payment_method?: string
  }): Promise<any> {
    try {
      await this.loadConfig()

      const data = {
        method: paymentData.payment_method || "BRIVA",
        merchant_ref: paymentData.merchant_ref,
        amount: paymentData.amount,
        customer_name: paymentData.customer_name,
        customer_email: paymentData.customer_email || "",
        customer_phone: paymentData.customer_phone,
        order_items: paymentData.order_items,
        return_url: `${process.env.FRONTEND_URL}/payment/callback`,
        expired_time: Math.floor(Date.now() / 1000) + 24 * 60 * 60, // 24 hours
        signature: "",
      }

      // Generate signature
      const signatureData = this.config.tripay_merchant_code + paymentData.merchant_ref + paymentData.amount
      data.signature = this.generateSignature(signatureData)

      const response = await axios.post(`${this.getBaseUrl()}/transaction/create`, data, {
        headers: {
          Authorization: `Bearer ${this.config.tripay_api_key}`,
          "Content-Type": "application/json",
        },
      })

      if (response.data.success) {
        logger.info(`TriPay payment created: ${paymentData.merchant_ref}`)
        return response.data.data
      } else {
        throw new Error(response.data.message || "Failed to create payment")
      }
    } catch (error) {
      logger.error("Error creating TriPay payment:", error)
      throw error
    }
  }

  async getPaymentDetail(reference: string): Promise<any> {
    try {
      await this.loadConfig()

      const response = await axios.get(`${this.getBaseUrl()}/transaction/detail`, {
        params: { reference },
        headers: {
          Authorization: `Bearer ${this.config.tripay_api_key}`,
        },
      })

      return response.data.data
    } catch (error) {
      logger.error("Error getting payment detail:", error)
      throw error
    }
  }
}

export const tripayService = new TriPayService()
