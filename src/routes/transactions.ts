import express from "express"
import { Pool } from "pg"
import { authenticateToken } from "../middleware/auth"
import { logger } from "../utils/logger"
import { tripayService } from "../services/tripayService"

const router = express.Router()
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
})

// POST /api/transactions - Create new transaction
router.post("/", async (req, res) => {
  try {
    const { package_id, customer_name, customer_phone, customer_email } = req.body

    // Get package details
    const packageResult = await pool.query("SELECT * FROM voucher_packages WHERE id = $1 AND enabled = true", [
      package_id,
    ])

    if (packageResult.rows.length === 0) {
      return res.status(404).json({ error: "Package not found or disabled" })
    }

    const packageData = packageResult.rows[0]

    // Create transaction record
    const transactionResult = await pool.query(
      `INSERT INTO transactions (package_id, customer_name, customer_phone, customer_email, amount, status) 
       VALUES ($1, $2, $3, $4, $5, 'pending') 
       RETURNING *`,
      [package_id, customer_name, customer_phone, customer_email, packageData.price],
    )

    const transaction = transactionResult.rows[0]

    // Create TriPay payment
    const paymentData = await tripayService.createPayment({
      merchant_ref: transaction.id,
      amount: packageData.price,
      customer_name,
      customer_email,
      customer_phone,
      order_items: [
        {
          name: packageData.name,
          price: packageData.price,
          quantity: 1,
        },
      ],
    })

    // Update transaction with payment reference
    await pool.query("UPDATE transactions SET payment_reference = $1, payment_url = $2 WHERE id = $3", [
      paymentData.reference,
      paymentData.checkout_url,
      transaction.id,
    ])

    logger.info(`Transaction created: ${transaction.id}`)
    res.status(201).json({
      transaction_id: transaction.id,
      payment_url: paymentData.checkout_url,
      payment_reference: paymentData.reference,
    })
  } catch (error) {
    logger.error("Error creating transaction:", error)
    res.status(500).json({ error: "Failed to create transaction" })
  }
})

// GET /api/transactions - Get all transactions (admin only)
router.get("/", authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT t.*, vp.name as package_name, vp.profile 
      FROM transactions t 
      JOIN voucher_packages vp ON t.package_id = vp.id 
      ORDER BY t.created_at DESC
    `)
    res.json(result.rows)
  } catch (error) {
    logger.error("Error fetching transactions:", error)
    res.status(500).json({ error: "Failed to fetch transactions" })
  }
})

// GET /api/transactions/:id - Get transaction by ID
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params
    const result = await pool.query(
      `
      SELECT t.*, vp.name as package_name, vp.profile 
      FROM transactions t 
      JOIN voucher_packages vp ON t.package_id = vp.id 
      WHERE t.id = $1
    `,
      [id],
    )

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Transaction not found" })
    }

    res.json(result.rows[0])
  } catch (error) {
    logger.error("Error fetching transaction:", error)
    res.status(500).json({ error: "Failed to fetch transaction" })
  }
})

export default router
