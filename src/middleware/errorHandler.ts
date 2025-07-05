import type { Request, Response, NextFunction } from "express"
import { logger } from "../utils/logger"

export const errorHandler = (error: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error("Unhandled error:", {
    error: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
  })

  res.status(500).json({
    success: false,
    message: "Internal server error",
    ...(process.env.NODE_ENV === "development" && { error: error.message }),
  })
}
