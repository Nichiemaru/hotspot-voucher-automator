import axios from "axios"
import crypto from "crypto"
import { logger } from "../utils/logger"

interface TriPayConfig {
  merchantCode: string
  apiKey: string
  privateKey: string
  baseUrl: string
}

interface CreateTransactionData {
  method: string
  merchant_ref: string
  amount: number
  customer_name: string
  customer_email: string
  customer_phone: string
  order_items: Array<{
    sku: string
    name: string
    price: number
    quantity: number
  }>
  return_url: string
  expired_time: number
}

class TriPayService {
  private config: TriPayConfig

  constructor() {
    this.config = {
      merchantCode: process.env.TRIPAY_MERCHANT_CODE || "T42431",
      apiKey: process.env.TRIPAY_API_KEY || "WfcMqxIr6QCFzeo5PT1PLKphuhqIqpURV9jGgMlN",
      privateKey: process.env.TRIPAY_PRIVATE_KEY || "Swu3P-JkeaZ-m9FnW-649ja-H0eD0",
      baseUrl: process.env.TRIPAY_BASE_URL || "https://tripay.co.id/api",
    }
  }

  private generateSignature(data: string): string {
    return crypto.createHmac("sha256", this.config.privateKey).update(data).digest("hex")
  }

  async createTransaction(data: CreateTransactionData) {
    try {
      const payload = JSON.stringify(data)
      const signature = this.generateSignature(payload)

      const response = await axios.post(`${this.config.baseUrl}/transaction/create`, data, {
        headers: {
          Authorization: `Bearer ${this.config.apiKey}`,
          "Content-Type": "application/json",
          "X-Signature": signature,
        },
      })

      logger.info("TriPay transaction created:", { reference: response.data.data?.reference })

      return {
        success: true,
        data: response.data.data,
        message: "Transaction created successfully",
      }
    } catch (error: any) {
      logger.error("TriPay create transaction error:", error.response?.data || error.message)

      return {
        success: false,
        message: error.response?.data?.message || "Failed to create transaction",
        data: null,
      }
    }
  }

  async getTransactionDetail(reference: string) {
    try {
      const response = await axios.get(`${this.config.baseUrl}/transaction/detail?reference=${reference}`, {
        headers: {
          Authorization: `Bearer ${this.config.apiKey}`,
          "Content-Type": "application/json",
        },
      })

      return {
        success: true,
        data: response.data.data,
        message: "Transaction detail retrieved successfully",
      }
    } catch (error: any) {
      logger.error("TriPay get transaction detail error:", error.response?.data || error.message)

      return {
        success: false,
        message: error.response?.data?.message || "Failed to get transaction detail",
        data: null,
      }
    }
  }

  async getPaymentChannels() {
    try {
      const response = await axios.get(`${this.config.baseUrl}/merchant/payment-channel`, {
        headers: {
          Authorization: `Bearer ${this.config.apiKey}`,
          "Content-Type": "application/json",
        },
      })

      return {
        success: true,
        data: response.data.data,
        message: "Payment channels retrieved successfully",
      }
    } catch (error: any) {
      logger.error("TriPay get payment channels error:", error.response?.data || error.message)

      return {
        success: false,
        message: error.response?.data?.message || "Failed to get payment channels",
        data: null,
      }
    }
  }

  // Method untuk frontend mengambil data paket
  async getPackages() {
    try {
      const response = await fetch("/api/packages")
      const result = await response.json()

      if (result.success) {
        return result.data
      }

      throw new Error(result.message)
    } catch (error) {
      console.error("Error fetching packages:", error)
      return []
    }
  }
}

const tripayService = new TriPayService()
export default tripayService
