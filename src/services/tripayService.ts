interface TriPayConfig {
  merchantCode: string;
  apiKey: string;
  privateKey: string;
}

interface CreateTransactionRequest {
  method: string;
  merchant_ref: string;
  amount: number;
  customer_name: string;
  customer_email: string;
  customer_phone: string;
  order_items: Array<{
    sku: string;
    name: string;
    price: number;
    quantity: number;
  }>;
  return_url: string;
  expired_time: number;
}

interface TriPayResponse {
  success: boolean;
  message: string;
  data?: {
    reference: string;
    merchant_ref: string;
    payment_selection_type: string;
    payment_method: string;
    payment_name: string;
    customer_name: string;
    customer_email: string;
    customer_phone: string;
    callback_url: string;
    return_url: string;
    amount: number;
    fee_merchant: number;
    fee_customer: number;
    total_fee: number;
    amount_received: number;
    pay_code: string;
    pay_url: string;
    checkout_url: string;
    status: string;
    expired_time: number;
    order_items: Array<any>;
    instructions: Array<{
      title: string;
      steps: Array<string>;
    }>;
    qr_code: string;
    qr_url: string;
    created_at: number;
    updated_at: number;
  };
}

class TriPayService {
  private config: TriPayConfig;
  private baseUrl = 'https://tripay.co.id/api';

  constructor() {
    // Menggunakan kredensial yang sudah diberikan
    this.config = {
      merchantCode: 'T42431',
      apiKey: 'WfcMqxIr6QCFzeo5PT1PLKphuhqIqpURV9jGgMlN',
      privateKey: 'Swu3P-JkeaZ-m9FnW-649ja-H0eD0'
    };
  }

  private generateSignature(data: string): string {
    // Implementasi signature sesuai dokumentasi TriPay
    const crypto = require('crypto');
    return crypto
      .createHmac('sha256', this.config.privateKey)
      .update(data)
      .digest('hex');
  }

  async getPaymentChannels() {
    try {
      const response = await fetch(`${this.baseUrl}/merchant/payment-channel`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${this.config.apiKey}`,
          'Content-Type': 'application/json'
        }
      });

      return await response.json();
    } catch (error) {
      console.error('Error fetching payment channels:', error);
      throw error;
    }
  }

  async createTransaction(data: CreateTransactionRequest): Promise<TriPayResponse> {
    try {
      // Generate signature
      const payload = JSON.stringify(data);
      const signature = this.generateSignature(payload);

      const response = await fetch(`${this.baseUrl}/transaction/create`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.config.apiKey}`,
          'Content-Type': 'application/json',
          'X-Signature': signature
        },
        body: payload
      });

      const result = await response.json();
      
      if (!response.ok) {
        throw new Error(result.message || 'Failed to create transaction');
      }

      return result;
    } catch (error) {
      console.error('Error creating transaction:', error);
      throw error;
    }
  }

  async getTransactionDetail(reference: string) {
    try {
      const response = await fetch(`${this.baseUrl}/transaction/detail?reference=${reference}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${this.config.apiKey}`,
          'Content-Type': 'application/json'
        }
      });

      return await response.json();
    } catch (error) {
      console.error('Error fetching transaction detail:', error);
      throw error;
    }
  }

  validateCallback(callbackData: any, signature: string): boolean {
    // Validasi signature callback dari TriPay
    const expectedSignature = this.generateSignature(JSON.stringify(callbackData));
    return expectedSignature === signature;
  }
}

export default new TriPayService();
