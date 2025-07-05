import { RouterOSAPI } from "node-routeros"
import { pool } from "../config/database"
import { logger } from "../utils/logger"

class MikroTikService {
  private conn: RouterOSAPI | null = null
  private config: any = {}

  async loadConfig() {
    try {
      const result = await pool.query(`
        SELECT key, value FROM system_config 
        WHERE key IN ('mikrotik_host', 'mikrotik_username', 'mikrotik_password')
      `)

      this.config = {}
      result.rows.forEach((row) => {
        this.config[row.key] = row.value
      })
    } catch (error) {
      logger.error("Error loading MikroTik config:", error)
      throw error
    }
  }

  async connect() {
    try {
      await this.loadConfig()

      if (!this.config.mikrotik_host || !this.config.mikrotik_username || !this.config.mikrotik_password) {
        throw new Error("MikroTik configuration is incomplete")
      }

      this.conn = new RouterOSAPI({
        host: this.config.mikrotik_host,
        user: this.config.mikrotik_username,
        password: this.config.mikrotik_password,
        timeout: 10,
      })

      await this.conn.connect()
      logger.info("Connected to MikroTik RouterOS")
    } catch (error) {
      logger.error("MikroTik connection error:", error)
      throw error
    }
  }

  async disconnect() {
    if (this.conn) {
      await this.conn.close()
      this.conn = null
      logger.info("Disconnected from MikroTik RouterOS")
    }
  }

  async checkProfile(profileName: string): Promise<boolean> {
    try {
      if (!this.conn) await this.connect()

      const profiles = await this.conn!.write("/ip/hotspot/user/profile/print", [`?name=${profileName}`])

      return profiles.length > 0
    } catch (error) {
      logger.error("Error checking MikroTik profile:", error)
      return false
    }
  }

  async createHotspotUser(username: string, password: string, profile: string): Promise<boolean> {
    try {
      if (!this.conn) await this.connect()

      // Check if user already exists
      const existingUsers = await this.conn!.write("/ip/hotspot/user/print", [`?name=${username}`])

      if (existingUsers.length > 0) {
        logger.warn(`User ${username} already exists in MikroTik`)
        return false
      }

      // Create new user
      await this.conn!.write("/ip/hotspot/user/add", [
        `=name=${username}`,
        `=password=${password}`,
        `=profile=${profile}`,
        "=disabled=no",
      ])

      logger.info(`Created MikroTik user: ${username} with profile: ${profile}`)
      return true
    } catch (error) {
      logger.error("Error creating MikroTik user:", error)
      throw error
    }
  }

  async getHotspotUsers(): Promise<any[]> {
    try {
      if (!this.conn) await this.connect()

      const users = await this.conn!.write("/ip/hotspot/user/print")
      return users
    } catch (error) {
      logger.error("Error getting MikroTik users:", error)
      throw error
    }
  }

  async getHotspotProfiles(): Promise<any[]> {
    try {
      if (!this.conn) await this.connect()

      const profiles = await this.conn!.write("/ip/hotspot/user/profile/print")
      return profiles
    } catch (error) {
      logger.error("Error getting MikroTik profiles:", error)
      throw error
    }
  }

  async deleteHotspotUser(username: string): Promise<boolean> {
    try {
      if (!this.conn) await this.connect()

      const users = await this.conn!.write("/ip/hotspot/user/print", [`?name=${username}`])

      if (users.length === 0) {
        logger.warn(`User ${username} not found in MikroTik`)
        return false
      }

      await this.conn!.write("/ip/hotspot/user/remove", [`=.id=${users[0][".id"]}`])

      logger.info(`Deleted MikroTik user: ${username}`)
      return true
    } catch (error) {
      logger.error("Error deleting MikroTik user:", error)
      throw error
    }
  }

  generateVoucherCode(): string {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let result = ""
    for (let i = 0; i < 8; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  generateVoucherPassword(): string {
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    let result = ""
    for (let i = 0; i < 6; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }
}

export const mikrotikService = new MikroTikService()
