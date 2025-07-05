import fs from "fs"
import path from "path"
import { pool } from "../config/database"
import { logger } from "../utils/logger"

async function runMigrations() {
  try {
    const migrationsDir = path.join(__dirname, "../../database/migrations")
    const migrationFiles = fs.readdirSync(migrationsDir).sort()

    for (const file of migrationFiles) {
      if (file.endsWith(".sql")) {
        logger.info(`Running migration: ${file}`)

        const migrationPath = path.join(migrationsDir, file)
        const migrationSQL = fs.readFileSync(migrationPath, "utf8")

        // Split by semicolon and execute each statement
        const statements = migrationSQL
          .split(";")
          .map((stmt) => stmt.trim())
          .filter((stmt) => stmt.length > 0)

        for (const statement of statements) {
          await pool.execute(statement)
        }

        logger.info(`Migration completed: ${file}`)
      }
    }

    logger.info("All migrations completed successfully")
    process.exit(0)
  } catch (error) {
    logger.error("Migration failed:", error)
    process.exit(1)
  }
}

runMigrations()
