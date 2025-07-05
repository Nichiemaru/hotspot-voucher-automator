import { Pool } from "pg"
import fs from "fs"
import path from "path"
import { logger } from "../utils/logger"

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
})

async function runMigrations() {
  try {
    // Create migrations table if it doesn't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `)

    // Get list of executed migrations
    const executedResult = await pool.query("SELECT filename FROM migrations")
    const executedMigrations = executedResult.rows.map((row) => row.filename)

    // Read migration files
    const migrationsDir = path.join(__dirname, "../database/migrations")
    const migrationFiles = fs
      .readdirSync(migrationsDir)
      .filter((file) => file.endsWith(".sql"))
      .sort()

    for (const file of migrationFiles) {
      if (!executedMigrations.includes(file)) {
        logger.info(`Running migration: ${file}`)

        const migrationSQL = fs.readFileSync(path.join(migrationsDir, file), "utf8")

        await pool.query(migrationSQL)
        await pool.query("INSERT INTO migrations (filename) VALUES ($1)", [file])

        logger.info(`Migration completed: ${file}`)
      }
    }

    logger.info("All migrations completed successfully")
  } catch (error) {
    logger.error("Migration error:", error)
    throw error
  }
}

// Run migrations if this file is executed directly
if (require.main === module) {
  runMigrations()
    .then(() => {
      logger.info("Migrations finished")
      process.exit(0)
    })
    .catch((error) => {
      logger.error("Migration failed:", error)
      process.exit(1)
    })
}

export { runMigrations }
