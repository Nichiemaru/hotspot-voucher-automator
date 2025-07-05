import { RouterOSAPI } from "node-routeros"
import { getOne } from "../config/database"
import { logger } from "../utils/logger"

interface MikrotikConfig {
  ipAddress: string
  username: string
  password: string
}

interface CreateUserData {
  username: string
  password: string
  profile: string
}

class MikrotikService {
  private async getConfig(): Promise<MikrotikConfig | null> {
    try {
      const ipConfig = await getOne("SELECT value FROM configurations WHERE key_name = ?", ["mikrotik_ip"])
      const usernameConfig = await getOne("SELECT value FROM configurations WHERE key_name = ?", ["mikrotik_username"])
      const passwordConfig = await getOne("SELECT value FROM configurations WHERE key_name = ?", ["mikrotik_password"])

      if (!ipConfig?.value || !usernameConfig?.value || !passwordConfig?.value) {
        return null
      }

      return {
        ipAddress: ipConfig.value,
        username: usernameConfig.value,
        password: passwordConfig.value,
      }
    } catch (error) {
      logger.error("Error getting MikroTik config:", error)
      return null
    }
  }

  async testConnection(config?: MikrotikConfig) {
    try {
      const mikrotikConfig = config || (await this.getConfig())

      if (!mikrotikConfig) {
        return {
          success: false,
          message: "MikroTik configuration not found",
        }
      }

      const conn = new RouterOSAPI({
        host: mikrotikConfig.ipAddress,
        user: mikrotikConfig.username,
        password: mikrotikConfig.password,
        timeout: 5,
      })

      await conn.connect()

      // Test by getting system identity
      const identity = await conn.write("/system/identity/print")

      await conn.close()

      logger.info("MikroTik connection test successful")

      return {
        success: true,
        message: "Connection successful",
        data: identity,
      }
    } catch (error: any) {
      logger.error("MikroTik connection test failed:", error.message)

      return {
        success: false,
        message: `Connection failed: ${error.message}`,
      }
    }
  }

  async createUser(userData: CreateUserData) {
    try {
      const config = await this.getConfig()

      if (!config) {
        return {
          success: false,
          message: "MikroTik configuration not found",
        }
      }

      const conn = new RouterOSAPI({
        host: config.ipAddress,
        user: config.username,
        password: config.password,
        timeout: 10,
      })

      await conn.connect()

      // Check if user already exists
      const existingUsers = await conn.write("/ip/hotspot/user/print", ["?name=" + userData.username])

      if (existingUsers && existingUsers.length > 0) {
        await conn.close()
        return {
          success: false,
          message: "Username already exists",
        }
      }

      // userData.profile berasal dari database voucher_packages.profile
      const result = await conn.write("/ip/hotspot/user/add", [
        "=name=" + userData.username,
        "=password=" + userData.password,
        "=profile=" + userData.profile, // ✅ Sesuai database
      ])

      await conn.close()

      logger.info("MikroTik user created:", { username: userData.username, profile: userData.profile })

      return {
        success: true,
        message: "User created successfully",
        data: {
          username: userData.username,
          profile: userData.profile, // ✅ Profile dari database
        },
      }
    } catch (error: any) {
      logger.error("MikroTik create user error:", error.message)

      // Error handling jika profile tidak ada di MikroTik
      return {
        success: false,
        message: `Failed to create user: ${error.message}`,
      }
    }
  }

  async getUsers() {
    try {
      const config = await this.getConfig()

      if (!config) {
        return {
          success: false,
          message: "MikroTik configuration not found",
        }
      }

      const conn = new RouterOSAPI({
        host: config.ipAddress,
        user: config.username,
        password: config.password,
        timeout: 10,
      })

      await conn.connect()

      const users = await conn.write("/ip/hotspot/user/print")

      await conn.close()

      return {
        success: true,
        message: "Users retrieved successfully",
        data: users,
      }
    } catch (error: any) {
      logger.error("MikroTik get users error:", error.message)

      return {
        success: false,
        message: `Failed to get users: ${error.message}`,
      }
    }
  }

  async getUserProfiles() {
    try {
      const config = await this.getConfig()

      if (!config) {
        return {
          success: false,
          message: "MikroTik configuration not found",
        }
      }

      const conn = new RouterOSAPI({
        host: config.ipAddress,
        user: config.username,
        password: config.password,
        timeout: 10,
      })

      await conn.connect()

      const profiles = await conn.write("/ip/hotspot/user/profile/print")

      await conn.close()

      return {
        success: true,
        message: "User profiles retrieved successfully",
        data: profiles,
      }
    } catch (error: any) {
      logger.error("MikroTik get user profiles error:", error.message)

      return {
        success: false,
        message: `Failed to get user profiles: ${error.message}`,
      }
    }
  }
}

const mikrotikService = new MikrotikService()

export const testMikrotikConnection = (config?: MikrotikConfig) => mikrotikService.testConnection(config)

export const createMikrotikUser = (userData: CreateUserData) => mikrotikService.createUser(userData)

export const getMikrotikUsers = () => mikrotikService.getUsers()

export const getMikrotikUserProfiles = () => mikrotikService.getUserProfiles()
