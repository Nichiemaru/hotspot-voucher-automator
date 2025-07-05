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

interface ApiResponse<T> {
  success: boolean
  message: string
  data: T
}

class ApiService {
  private baseUrl = "/api"

  async getPackages(): Promise<VoucherPackage[]> {
    try {
      const response = await fetch(`${this.baseUrl}/packages`)
      const result: ApiResponse<VoucherPackage[]> = await response.json()

      if (result.success) {
        return result.data
      }

      throw new Error(result.message)
    } catch (error) {
      console.error("Error fetching packages:", error)
      // Fallback ke data hardcoded jika API belum ready
      return [
        {
          id: 1,
          name: "Paket Hemat 1 Jam",
          profile: "1jam",
          price: 2000,
          duration: "1 Jam",
          speed: "2 Mbps",
          description: "Cocok untuk browsing ringan dan media sosial",
          enabled: true,
        },
        {
          id: 2,
          name: "Paket Super Cepat 6 Jam",
          profile: "6jam",
          price: 5000,
          duration: "6 Jam",
          speed: "5 Mbps",
          description: "Ideal untuk streaming dan download",
          enabled: true,
        },
        {
          id: 3,
          name: "Paket Premium 24 Jam",
          profile: "1hari",
          price: 10000,
          duration: "24 Jam",
          speed: "10 Mbps",
          description: "Unlimited browsing untuk seharian penuh",
          enabled: true,
        },
        {
          id: 4,
          name: "Paket Mingguan",
          profile: "1minggu",
          price: 50000,
          duration: "7 Hari",
          speed: "10 Mbps",
          description: "Paket hemat untuk kebutuhan seminggu",
          enabled: true,
        },
      ]
    }
  }

  async updatePackages(packages: Omit<VoucherPackage, "id">[]): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/packages/bulk-update`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("admin_token")}`,
        },
        body: JSON.stringify({ packages }),
      })

      const result: ApiResponse<any> = await response.json()
      return result.success
    } catch (error) {
      console.error("Error updating packages:", error)
      return false
    }
  }

  async createTransaction(data: {
    packageId: number
    customerName: string
    customerEmail: string
    customerPhone: string
  }) {
    try {
      const response = await fetch(`${this.baseUrl}/transactions/create`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      })

      const result = await response.json()
      return result
    } catch (error) {
      console.error("Error creating transaction:", error)
      throw error
    }
  }
}

export default new ApiService()
