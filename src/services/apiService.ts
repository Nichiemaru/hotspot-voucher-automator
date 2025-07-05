const API_BASE_URL = process.env.VITE_API_URL || "http://localhost:3001/api"

interface VoucherPackage {
  id: number
  name: string
  profile: string
  price: number
  duration: string
  speed: string
  description: string
  enabled: boolean
}

interface CreateTransactionRequest {
  packageId: number
  customerName: string
  customerEmail: string
  customerPhone: string
}

interface ApiResponse<T> {
  success: boolean
  message: string
  data: T
  token?: string
}

class ApiService {
  private async request(endpoint: string, options: RequestInit = {}) {
    const url = `${API_BASE_URL}${endpoint}`

    const config: RequestInit = {
      headers: {
        "Content-Type": "application/json",
        ...options.headers,
      },
      ...options,
    }

    // Add auth token if available
    const token = localStorage.getItem("admin_token")
    if (token) {
      config.headers = {
        ...config.headers,
        Authorization: `Bearer ${token}`,
      }
    }

    const response = await fetch(url, config)

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: "Network error" }))
      throw new Error(error.error || `HTTP ${response.status}`)
    }

    return response.json()
  }

  // Packages
  async getPackages(): Promise<VoucherPackage[]> {
    return this.request("/packages")
  }

  async getAdminPackages(): Promise<VoucherPackage[]> {
    return this.request("/packages/admin")
  }

  async updatePackage(id: number, packageData: Partial<VoucherPackage>): Promise<VoucherPackage> {
    return this.request(`/packages/${id}`, {
      method: "PUT",
      body: JSON.stringify(packageData),
    })
  }

  async createPackage(packageData: Omit<VoucherPackage, "id">): Promise<VoucherPackage> {
    return this.request("/packages", {
      method: "POST",
      body: JSON.stringify(packageData),
    })
  }

  async deletePackage(id: number): Promise<void> {
    return this.request(`/packages/${id}`, {
      method: "DELETE",
    })
  }

  // Transactions
  async createTransaction(transactionData: CreateTransactionRequest) {
    return this.request("/transactions", {
      method: "POST",
      body: JSON.stringify(transactionData),
    })
  }

  async getTransactions() {
    return this.request("/transactions")
  }

  async getTransaction(id: string) {
    return this.request(`/transactions/${id}`)
  }

  // Auth
  async login(username: string, password: string) {
    const response = await this.request("/auth/login", {
      method: "POST",
      body: JSON.stringify({ username, password }),
    })

    if (response.token) {
      localStorage.setItem("admin_token", response.token)
    }

    return response
  }

  async changePassword(currentPassword: string, newPassword: string, username: string) {
    return this.request("/auth/change-password", {
      method: "POST",
      body: JSON.stringify({ currentPassword, newPassword, username }),
    })
  }

  // Config
  async getConfig() {
    return this.request("/config")
  }

  async updateConfig(configs: Record<string, any>) {
    return this.request("/config", {
      method: "PUT",
      body: JSON.stringify({ configs }),
    })
  }

  // MikroTik
  async testMikrotikConnection(host: string, username: string, password: string) {
    return this.request("/mikrotik/test-connection", {
      method: "POST",
      body: JSON.stringify({ host, username, password }),
    })
  }

  async getMikrotikProfiles() {
    return this.request("/mikrotik/profiles")
  }

  async getMikrotikUsers() {
    return this.request("/mikrotik/users")
  }
}

export default new ApiService()
