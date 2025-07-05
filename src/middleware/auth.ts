import type { Request, Response, NextFunction } from "express"
import jwt from "jsonwebtoken"
import { getOne } from "../config/database"

interface AuthRequest extends Request {
  user?: any
}

export const authenticateToken = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers["authorization"]
  const token = authHeader && authHeader.split(" ")[1]

  if (!token) {
    return res.status(401).json({
      success: false,
      message: "Access token required",
    })
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key") as any

    // Verify user still exists
    const user = await getOne("SELECT id, username, email FROM admin_users WHERE id = ?", [decoded.userId])

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      })
    }

    req.user = user
    next()
  } catch (error) {
    return res.status(403).json({
      success: false,
      message: "Invalid or expired token",
    })
  }
}
