import { RouterOSAPI } from "node-routeros"
import { configService } from "./configService"
import { logger } from "../utils/logger"

class MikroTikService {
  private conn: RouterOSAPI | null = null

  // ✅ CONNECT KE MIKROTIK
  async connect(): Promise<boolean> {
    try {
      const host = await configService.getConfig("mikrotik_host")
      const username = await configService.getConfig("mikrotik_username")
      const password = await configService.getConfig("mikrotik_password")

      if (!host || !username || !password) {
        throw new Error("MikroTik configuration incomplete")
      }

      this.conn = new RouterOSAPI({
        host,
        user: username,
        password,
        timeout: 10,
      })

      await this.conn.connect()
      logger.info(`✅ Connected to MikroTik: ${host}`)
      return true
    } catch (error) {
      logger.error("❌ MikroTik connection failed:", error)
      return false
    }
  }

  // ✅ BENAR-BENAR CREATE USER DI MIKROTIK
  async createHotspotUser(username: string, password: string, profile: string): Promise<boolean> {
    try {
      if (!this.conn) {
        const connected = await this.connect()
        if (!connected) return false
      }

      // Check if user already exists
      const existingUsers = await this.conn!.write("/ip/hotspot/user/print", [`?name=${username}`])

      if (existingUsers.length > 0) {
        logger.warn(`⚠️ User ${username} already exists in MikroTik`)
        return false
      }

      // ✅ CREATE NEW HOTSPOT USER
      await this.conn!.write("/ip/hotspot/user/add", [
        `=name=${username}`,
        `=password=${password}`,
        `=profile=${profile}`,
        "=disabled=no",
        `=comment=Auto-generated voucher - ${new Date().toISOString()}`,
      ])

      logger.info(`✅ MikroTik user created: ${username} with profile: ${profile}`)
      return true
    } catch (error) {
      logger.error("❌ Error creating MikroTik user:", error)
      return false
    }
  }

  // ✅ GENERATE UNIQUE VOUCHER CODE
  generateVoucherCode(): string {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let result = ""
    for (let i = 0; i < 8; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  // ✅ GENERATE SECURE PASSWORD
  generateVoucherPassword(): string {
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    let result = ""
    for (let i = 0; i < 6; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  // ✅ CHECK PROFILE EXISTS
  async checkProfile(profileName: string): Promise<boolean> {
    try {
      if (!this.conn) {
        const connected = await this.connect()
        if (!connected) return false
      }

      const profiles = await this.conn!.write("/ip/hotspot/user/profile/print", [`?name=${profileName}`])

      return profiles.length > 0
    } catch (error) {
      logger.error("Error checking MikroTik profile:", error)
      return false
    }
  }
}

export const mikrotikService = new MikroTikService()
