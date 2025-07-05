import express from "express"
import cors from "cors"
import helmet from "helmet"
import rateLimit from "express-rate-limit"
import { errorHandler } from "./middleware/errorHandler"
import { logger } from "./utils/logger"

// Import routes
import authRoutes from "./routes/auth"
import packagesRoutes from "./routes/packages"
import transactionsRoutes from "./routes/transactions"
import configRoutes from "./routes/config"
import webhooksRoutes from "./routes/webhooks"
import mikrotikRoutes from "./routes/mikrotik"

const app = express()
const PORT = process.env.PORT || 3001

// Security middleware
app.use(helmet())
app.use(
  cors({
    origin: process.env.FRONTEND_URL || "http://localhost:5173",
    credentials: true,
  }),
)

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
})
app.use(limiter)

// Body parsing middleware
app.use(express.json({ limit: "10mb" }))
app.use(express.urlencoded({ extended: true }))

// Logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path} - ${req.ip}`)
  next()
})

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "OK", timestamp: new Date().toISOString() })
})

// API routes
app.use("/api/auth", authRoutes)
app.use("/api/packages", packagesRoutes)
app.use("/api/transactions", transactionsRoutes)
app.use("/api/config", configRoutes)
app.use("/api/webhooks", webhooksRoutes)
app.use("/api/mikrotik", mikrotikRoutes)

// Error handling middleware
app.use(errorHandler)

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({ error: "Route not found" })
})

app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`)
})

export default app
