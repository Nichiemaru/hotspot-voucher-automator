import type { Request, Response, NextFunction } from "express"
import { logger } from "../utils/logger"

export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
  logger.error("Unhandled error:", {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
  })

  // Don't leak error details in production
  if (process.env.NODE_ENV === "production") {
    res.status(500).json({ error: "Internal server error" })
  } else {
    res.status(500).json({
      error: err.message,
      stack: err.stack,
    })
  }
}
