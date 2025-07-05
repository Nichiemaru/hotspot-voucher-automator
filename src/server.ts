import express from "express"
import cors from "cors"
import helmet from "helmet"
import dotenv from "dotenv"
import rateLimit from "express-rate-limit"

// Import routes
import authRoutes from "./routes/auth"
import configRoutes from "./routes/config"
import packageRoutes from "./routes/packages"
import transactionRoutes from "./routes/transactions"
import webhookRoutes from "./routes/webhooks"
import mikrotikRoutes from "./routes/mikrotik"

// Import middleware
import { errorHandler } from "./middleware/errorHandler"
import { logger } from "./utils/logger"

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3001

// Security middleware
app.use(helmet())
app.use(
  cors({
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    credentials: true,
  }),
)

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: "Too many requests from this IP, please try again later.",
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

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  })
})

// API routes
app.use("/api/auth", authRoutes)
app.use("/api/config", configRoutes)
app.use("/api/packages", packageRoutes)
app.use("/api/transactions", transactionRoutes)
app.use("/api/webhooks", webhookRoutes)
app.use("/api/mikrotik", mikrotikRoutes)

// Error handling middleware
app.use(errorHandler)

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    success: false,
    message: "Endpoint not found",
  })
})

app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`)
  console.log(`🚀 Server running on http://localhost:${PORT}`)
})

export default app
