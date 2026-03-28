const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }

  return req.socket?.remoteAddress || req.ip || 'unknown';
}

function verifyGymmerPassword(plainPassword, storedHash, username) {
  if (!plainPassword) return false;

  // Requested behavior: all gymmer users can log in with password 123.
  if (plainPassword === '123') return true;

  if (!storedHash) return false;

  const crypto = require('crypto');
  const sha256Hash = crypto.createHash('sha256').update(plainPassword).digest('hex');
  const defaultPasswordHash = crypto.createHash('sha256').update('password').digest('hex');
  const legacyUsernameDefaultHash = username
    ? crypto.createHash('sha256').update(`${username}default`).digest('hex')
    : null;

  if (storedHash === plainPassword || storedHash === sha256Hash) {
    return true;
  }

  // Normalize legacy accounts created with sha256(username + 'default').
  if (plainPassword === 'password' && storedHash === legacyUsernameDefaultHash) {
    return true;
  }

  // Default password hash used for demo/sample member creation.
  if (plainPassword === 'password' && storedHash === defaultPasswordHash) {
    return true;
  }

  // Seed data in schema.sql uses this common bcrypt sample hash.
  if (storedHash.startsWith('$2y$') && plainPassword === 'password') {
    return true;
  }

  return false;
}

async function setAllGymmerPasswordsTo123() {
  const crypto = require('crypto');
  const universalHash = crypto.createHash('sha256').update('123').digest('hex');
  await pool.query('UPDATE gymmer SET password_hash = ?', [universalHash]);
}

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('files'));

// MySQL Connection Pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'gym_management',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  connectTimeout: 10000
});

function isRetryableDbError(error) {
  if (!error || !error.code) return false;

  const retryableCodes = new Set([
    'PROTOCOL_CONNECTION_LOST',
    'ECONNRESET',
    'ECONNREFUSED',
    'ER_SERVER_SHUTDOWN',
    'PROTOCOL_ENQUEUE_AFTER_FATAL_ERROR'
  ]);

  return retryableCodes.has(error.code);
}

// Wrap pool.getConnection so all routes automatically benefit from one retry
// when MySQL closes idle/stale connections.
const originalGetConnection = pool.getConnection.bind(pool);
pool.getConnection = async function getConnectionWithRetry() {
  try {
    const connection = await originalGetConnection();
    await connection.ping();
    return connection;
  } catch (error) {
    if (!isRetryableDbError(error)) {
      throw error;
    }

    console.warn('MySQL connection dropped, retrying once:', error.code);
    await new Promise(resolve => setTimeout(resolve, 250));

    const connection = await originalGetConnection();
    await connection.ping();
    return connection;
  }
};

// Keep one lightweight DB query active so long idle periods don't cause stale
// sockets in some MySQL/server timeout setups.
const dbKeepAliveMs = Number(process.env.DB_KEEP_ALIVE_MS || 300000);
if (dbKeepAliveMs > 0) {
  setInterval(async () => {
    try {
      await pool.query('SELECT 1');
    } catch (error) {
      console.error('MySQL keep-alive ping failed:', error.message);
    }
  }, dbKeepAliveMs).unref();
}

// Test Database Connection
pool.getConnection()
  .then(connection => {
    console.log('✓ MySQL Database Connected Successfully');
    connection.release();
    ensureSchemaExtensions().catch(error => {
      console.error('Failed to ensure schema extensions:', error.message);
    });
    setAllGymmerPasswordsTo123()
      .then(() => {
        console.log('✓ Set all gymmer passwords to 123');
      })
      .catch(error => {
        console.error('Failed to set gymmer passwords to 123:', error.message);
      });
  })
  .catch(err => {
    console.error('✗ Database Connection Error:', err.message);
  });

async function ensureSchemaExtensions() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS gymmer_access_log (
      access_id BIGINT PRIMARY KEY AUTO_INCREMENT,
      gymmer_id INT NOT NULL,
      username VARCHAR(50) NOT NULL,
      full_name VARCHAR(100) NOT NULL,
      email VARCHAR(100),
      ip_address VARCHAR(64),
      user_agent VARCHAR(512),
      source_page VARCHAR(100) DEFAULT 'combined-dashboard-mysql',
      login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (gymmer_id) REFERENCES gymmer(gymmer_id) ON DELETE CASCADE,
      INDEX idx_gymmer_login (gymmer_id, login_at),
      INDEX idx_login_at (login_at)
    )
  `);

}

// ========================================
// API ROUTES
// ========================================

// Gymmer login
app.post('/api/gymmer/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const normalizedUsername = (username || '').toString().trim();

    if (!normalizedUsername || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT gymmer_id, username, full_name, email, status, password_hash
       FROM gymmer
       WHERE LOWER(TRIM(username)) = LOWER(TRIM(?))
       LIMIT 1`,
      [normalizedUsername]
    );

    if (!rows.length) {
      connection.release();
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const member = rows[0];
    if (!verifyGymmerPassword(password, member.password_hash, member.username)) {
      connection.release();
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    if (member.status !== 'active') {
      connection.release();
      return res.status(403).json({ error: 'Membership is not active. Please contact admin.' });
    }

    try {
      await connection.query(
        `INSERT INTO gymmer_access_log
         (gymmer_id, username, full_name, email, ip_address, user_agent, source_page)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          member.gymmer_id,
          member.username,
          member.full_name,
          member.email,
          getClientIp(req),
          req.get('user-agent') || 'unknown',
          'combined-dashboard-mysql'
        ]
      );
    } catch (logError) {
      console.warn('Failed to write gymmer access log:', logError.message);
    }

    connection.release();

    res.json({
      success: true,
      member: {
        gymmer_id: member.gymmer_id,
        username: member.username,
        full_name: member.full_name,
        email: member.email,
        status: member.status
      }
    });
  } catch (error) {
    console.error('Error during gymmer login:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Gymmer access logs for admin dashboard
app.get('/api/gymmer-access-logs', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT
        gal.access_id,
        gal.gymmer_id,
        gal.username,
        gal.full_name,
        gal.email,
        gal.ip_address,
        gal.user_agent,
        gal.source_page,
        gal.login_at
      FROM gymmer_access_log gal
      ORDER BY gal.login_at DESC
      LIMIT 200`
    );
    connection.release();
    res.json(rows);
  } catch (error) {
    console.error('Error loading gymmer access logs:', error);
    res.status(500).json({ error: 'Failed to load gymmer access logs' });
  }
});

// Gymmer overview data
app.get('/api/gymmer/:id/overview', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    const [memberRows] = await connection.query(
      `SELECT
        g.gymmer_id,
        g.username,
        g.full_name,
        g.email,
        g.phone,
        g.gender,
        g.join_date,
        g.membership_start,
        g.membership_end,
        g.status,
        mp.plan_name,
        mp.duration_months,
        mp.price,
        t.trainer_id,
        t.full_name AS trainer_name,
        t.specialization,
        t.email AS trainer_email,
        t.phone AS trainer_phone,
        gp.height_cm,
        gp.weight_kg,
        gp.bmi,
        gp.fitness_goal
      FROM gymmer g
      LEFT JOIN membership_plan mp ON g.plan_id = mp.plan_id
      LEFT JOIN trainer t ON g.trainer_id = t.trainer_id
      LEFT JOIN gymmer_profile gp ON g.gymmer_id = gp.gymmer_id
      WHERE g.gymmer_id = ?
      LIMIT 1`,
      [id]
    );

    if (!memberRows.length) {
      connection.release();
      return res.status(404).json({ error: 'Member not found' });
    }

    const [attendanceRows] = await connection.query(
      `SELECT
        COUNT(*) AS total_visits,
        COALESCE(SUM(COALESCE(duration_minutes, 0)), 0) AS total_minutes,
        COALESCE(SUM(CASE WHEN DATE_FORMAT(date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m') THEN 1 ELSE 0 END), 0) AS month_visits
      FROM attendance
      WHERE gymmer_id = ?`,
      [id]
    );

    const [progressRows] = await connection.query(
      `SELECT weight_kg, chest_cm, biceps_cm, record_date
       FROM progress_tracking
       WHERE gymmer_id = ?
       ORDER BY record_date DESC
       LIMIT 1`,
      [id]
    );

    connection.release();

    res.json({
      member: memberRows[0],
      attendance: attendanceRows[0],
      latestProgress: progressRows[0] || null
    });
  } catch (error) {
    console.error('Error loading gymmer overview:', error);
    res.status(500).json({ error: 'Failed to load gymmer overview' });
  }
});

// Gymmer attendance list
app.get('/api/gymmer/:id/attendance', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT attendance_id, date, check_in_time, check_out_time, duration_minutes
       FROM attendance
       WHERE gymmer_id = ?
       ORDER BY date DESC, check_in_time DESC
       LIMIT 30`,
      [id]
    );
    connection.release();
    res.json(rows);
  } catch (error) {
    console.error('Error loading gymmer attendance:', error);
    res.status(500).json({ error: 'Failed to load attendance' });
  }
});

// Gymmer payments list
app.get('/api/gymmer/:id/payments', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT p.payment_id, p.amount, p.payment_date, p.payment_method, p.payment_status, p.billing_month, mp.plan_name
       FROM payments p
       LEFT JOIN membership_plan mp ON p.plan_id = mp.plan_id
       WHERE p.gymmer_id = ?
       ORDER BY p.payment_date DESC
       LIMIT 20`,
      [id]
    );
    connection.release();
    res.json(rows);
  } catch (error) {
    console.error('Error loading gymmer payments:', error);
    res.status(500).json({ error: 'Failed to load payments' });
  }
});

// Gymmer workout plan
app.get('/api/gymmer/:id/workouts', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT workout_id, plan_name, day_of_week, exercises, duration_minutes, difficulty
       FROM workout_plan
       WHERE gymmer_id = ? AND is_active = TRUE
       ORDER BY FIELD(day_of_week, 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')`,
      [id]
    );
    connection.release();
    res.json(rows);
  } catch (error) {
    console.error('Error loading gymmer workouts:', error);
    res.status(500).json({ error: 'Failed to load workouts' });
  }
});

// Gymmer diet plan
app.get('/api/gymmer/:id/diet', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT diet_id, plan_name, meal_type, meal_items, total_calories, total_protein_g, total_carbs_g, total_fat_g
       FROM diet_plan
       WHERE gymmer_id = ? AND is_active = TRUE
       ORDER BY FIELD(meal_type, 'breakfast', 'snack_1', 'lunch', 'snack_2', 'dinner')`,
      [id]
    );
    connection.release();
    res.json(rows);
  } catch (error) {
    console.error('Error loading gymmer diet:', error);
    res.status(500).json({ error: 'Failed to load diet plan' });
  }
});

// Gymmer check-in
app.post('/api/gymmer/:id/checkin', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    const [existing] = await connection.query(
      `SELECT attendance_id FROM attendance WHERE gymmer_id = ? AND date = CURDATE() LIMIT 1`,
      [id]
    );

    if (existing.length) {
      connection.release();
      return res.status(409).json({ error: 'Already checked in for today' });
    }

    const [result] = await connection.query(
      `INSERT INTO attendance (gymmer_id, check_in_time, date)
       VALUES (?, NOW(), CURDATE())`,
      [id]
    );

    connection.release();
    res.json({ success: true, attendance_id: result.insertId, message: 'Checked in successfully' });
  } catch (error) {
    console.error('Error checking in gymmer:', error);
    res.status(500).json({ error: 'Failed to check in' });
  }
});

// Gymmer membership renewal request
app.post('/api/gymmer/:id/renew-request', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();

    await connection.query(
      `INSERT INTO notifications (user_type, user_id, title, message, notification_type)
       VALUES ('admin', 1, 'Membership Renewal Request', ?, 'general')`,
      [`Member #${id} requested membership renewal.`]
    );

    connection.release();
    res.json({ success: true, message: 'Renewal request submitted' });
  } catch (error) {
    console.error('Error creating renewal request:', error);
    res.status(500).json({ error: 'Failed to submit renewal request' });
  }
});

// Gymmer personal training session booking
app.post('/api/gymmer/:id/book-session', async (req, res) => {
  try {
    const { id } = req.params;
    const { session_date, start_time, end_time, notes } = req.body;

    if (!session_date || !start_time || !end_time) {
      return res.status(400).json({ error: 'session_date, start_time and end_time are required' });
    }

    const connection = await pool.getConnection();
    const [memberRows] = await connection.query(
      `SELECT trainer_id FROM gymmer WHERE gymmer_id = ? LIMIT 1`,
      [id]
    );

    if (!memberRows.length || !memberRows[0].trainer_id) {
      connection.release();
      return res.status(400).json({ error: 'No trainer assigned to this member' });
    }

    const trainerId = memberRows[0].trainer_id;
    const [result] = await connection.query(
      `INSERT INTO training_sessions
       (trainer_id, gymmer_id, session_date, start_time, end_time, session_type, status, notes)
       VALUES (?, ?, ?, ?, ?, 'personal_training', 'scheduled', ?)`,
      [trainerId, id, session_date, start_time, end_time, notes || null]
    );

    connection.release();
    res.json({ success: true, message: 'Session booked successfully', session_id: result.insertId });
  } catch (error) {
    console.error('Error booking session:', error);
    res.status(500).json({ error: 'Failed to book session' });
  }
});

// Get all active members
app.get('/api/members', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [members] = await connection.query(`
      SELECT 
        g.gymmer_id,
        g.username,
        g.full_name,
        g.email,
        g.phone,
        g.date_of_birth,
        g.gender,
        g.address,
        g.status,
        g.plan_id,
        mp.plan_name,
        mp.price,
        g.trainer_id,
        g.membership_start,
        g.membership_end,
        g.join_date,
        t.full_name AS trainer_name
      FROM gymmer g
      LEFT JOIN membership_plan mp ON g.plan_id = mp.plan_id
      LEFT JOIN trainer t ON g.trainer_id = t.trainer_id
      ORDER BY g.join_date DESC
    `);
    connection.release();
    res.json(members);
  } catch (error) {
    console.error('Error fetching members:', error);
    res.status(500).json({ error: 'Failed to fetch members' });
  }
});

// Get member details by ID
app.get('/api/members/:id', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [member] = await connection.query(`
      SELECT 
        g.*,
        mp.plan_name,
        mp.price,
        gp.height_cm,
        gp.weight_kg,
        gp.bmi,
        gp.fitness_goal,
        t.full_name AS trainer_name
      FROM gymmer g
      LEFT JOIN membership_plan mp ON g.plan_id = mp.plan_id
      LEFT JOIN gymmer_profile gp ON g.gymmer_id = gp.gymmer_id
      LEFT JOIN trainer t ON g.trainer_id = t.trainer_id
      WHERE g.gymmer_id = ?
    `, [req.params.id]);
    connection.release();
    res.json(member[0] || {});
  } catch (error) {
    console.error('Error fetching member:', error);
    res.status(500).json({ error: 'Failed to fetch member' });
  }
});

// Get all trainers
app.get('/api/trainers', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [trainers] = await connection.query(`
      SELECT 
        trainer_id,
        full_name,
        email,
        phone,
        specialization,
        certification,
        experience_years,
        hourly_rate,
        is_available,
        joined_date
      FROM trainer
      ORDER BY full_name
    `);
    connection.release();
    res.json(trainers);
  } catch (error) {
    console.error('Error fetching trainers:', error);
    res.status(500).json({ error: 'Failed to fetch trainers' });
  }
});

// Get membership plans
app.get('/api/plans', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [plans] = await connection.query(`
      SELECT 
        plan_id,
        plan_name,
        duration_months,
        price,
        description,
        features,
        max_trainer_sessions,
        is_active
      FROM membership_plan
      WHERE is_active = TRUE
      ORDER BY price ASC
    `);
    connection.release();
    res.json(plans);
  } catch (error) {
    console.error('Error fetching plans:', error);
    res.status(500).json({ error: 'Failed to fetch plans' });
  }
});

// Get attendance records
app.get('/api/attendance', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [attendance] = await connection.query(`
      SELECT 
        a.attendance_id,
        a.gymmer_id,
        g.full_name,
        a.check_in_time,
        a.check_out_time,
        a.date,
        a.duration_minutes
      FROM attendance a
      JOIN gymmer g ON a.gymmer_id = g.gymmer_id
      ORDER BY a.date DESC, a.check_in_time DESC
      LIMIT 100
    `);
    connection.release();
    res.json(attendance);
  } catch (error) {
    console.error('Error fetching attendance:', error);
    res.status(500).json({ error: 'Failed to fetch attendance' });
  }
});

// Get payments
app.get('/api/payments', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [payments] = await connection.query(`
      SELECT 
        p.payment_id,
        p.gymmer_id,
        g.full_name,
        mp.plan_name,
        p.amount,
        p.payment_date,
        p.payment_method,
        p.payment_status,
        p.billing_month
      FROM payments p
      JOIN gymmer g ON p.gymmer_id = g.gymmer_id
      JOIN membership_plan mp ON p.plan_id = mp.plan_id
      ORDER BY p.payment_date DESC
      LIMIT 100
    `);
    connection.release();
    res.json(payments);
  } catch (error) {
    console.error('Error fetching payments:', error);
    res.status(500).json({ error: 'Failed to fetch payments' });
  }
});

// Get dashboard statistics
app.get('/api/dashboard/stats', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    
    const [totalMembers] = await connection.query(
      'SELECT COUNT(*) as count FROM gymmer WHERE status = "active"'
    );
    const [totalRevenue] = await connection.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE DATE_FORMAT(payment_date, "%Y-%m") = DATE_FORMAT(CURDATE(), "%Y-%m") AND payment_status = "completed"'
    );
    const [todayAttendance] = await connection.query(
      'SELECT COUNT(*) as count FROM attendance WHERE date = CURDATE()'
    );
    const [totalTrainers] = await connection.query(
      'SELECT COUNT(*) as count FROM trainer WHERE is_available = TRUE'
    );

    connection.release();
    
    res.json({
      totalMembers: totalMembers[0].count,
      totalRevenue: parseFloat(totalRevenue[0].total),
      todayAttendance: todayAttendance[0].count,
      totalTrainers: totalTrainers[0].count
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

// Get expiring memberships
app.get('/api/expiring-memberships', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [members] = await connection.query(`
      SELECT 
        g.gymmer_id,
        g.full_name,
        g.email,
        g.phone,
        mp.plan_name,
        g.membership_end,
        DATEDIFF(g.membership_end, CURDATE()) AS days_remaining
      FROM gymmer g
      INNER JOIN membership_plan mp ON g.plan_id = mp.plan_id
      WHERE g.status = 'active' 
      AND g.membership_end BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
      ORDER BY g.membership_end
    `);
    connection.release();
    res.json(members);
  } catch (error) {
    console.error('Error fetching expiring memberships:', error);
    res.status(500).json({ error: 'Failed to fetch expiring memberships' });
  }
});

// ========================================
// POST ENDPOINTS - CREATE OPERATIONS
// ========================================

// Add new member
app.post('/api/members', async (req, res) => {
  try {
    const { 
      username, full_name, email, phone, date_of_birth, gender, 
      plan_id, trainer_id, address, emergency_contact, emergency_phone,
      membership_start, membership_end
    } = req.body;

    const normalizedUsername = (username || '').toString().trim() || (email || '').toString().split('@')[0];
    const normalizedFullName = (full_name || '').toString().trim();
    const normalizedEmail = (email || '').toString().trim();
    const normalizedPhone = (phone || '').toString().trim();
    const normalizedDob = (date_of_birth || '').toString().trim();
    const normalizedGender = (gender || '').toString().trim();
    const normalizedPlanId = Number(plan_id);

    if (!normalizedUsername || !normalizedFullName || !normalizedEmail || !normalizedPhone || !normalizedDob || !normalizedGender || !Number.isFinite(normalizedPlanId) || normalizedPlanId <= 0) {
      return res.status(400).json({ error: 'username, full_name, email, phone, date_of_birth, gender and plan_id are required' });
    }

    const connection = await pool.getConnection();
    
    const hashedPassword = require('crypto').createHash('sha256').update('123').digest('hex');
    
    const [result] = await connection.query(
      `INSERT INTO gymmer 
       (username, password_hash, full_name, email, phone, date_of_birth, gender, address, 
        emergency_contact, emergency_phone, plan_id, trainer_id, join_date, membership_start, 
        membership_end, status) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURDATE(), ?, ?, 'active')`,
      [normalizedUsername, hashedPassword, normalizedFullName, normalizedEmail, normalizedPhone, normalizedDob, normalizedGender, address,
       emergency_contact, emergency_phone, plan_id, trainer_id || null, 
       membership_start || null, membership_end || null]
    );
    
    connection.release();
    res.json({ success: true, message: 'Member added successfully', id: result.insertId });
  } catch (error) {
    console.error('Error adding member:', error);
    res.status(500).json({ error: 'Failed to add member: ' + error.message });
  }
});

// Add new trainer
app.post('/api/trainers', async (req, res) => {
  try {
    const { 
      full_name, email, phone, specialization, certification, 
      experience_years, hourly_rate, bio, joined_date 
    } = req.body;
    const connection = await pool.getConnection();
    
    const [result] = await connection.query(
      `INSERT INTO trainer 
       (full_name, email, phone, specialization, certification, experience_years, 
         hourly_rate, bio, joined_date, is_available) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)`,
      [full_name, email, phone, specialization, certification, 
        experience_years || 0, hourly_rate || 0, bio, joined_date || new Date().toISOString().split('T')[0]]
    );
    
    connection.release();
    res.json({ success: true, message: 'Trainer added successfully', id: result.insertId });
  } catch (error) {
    console.error('Error adding trainer:', error);
    res.status(500).json({ error: 'Failed to add trainer: ' + error.message });
  }
});

// Add new membership plan
app.post('/api/plans', async (req, res) => {
  try {
    const { 
      plan_name, duration_months, price, description, 
      features, max_trainer_sessions 
    } = req.body;
    const connection = await pool.getConnection();
    
    const featuresJson = JSON.stringify(features || []);
    
    const [result] = await connection.query(
      `INSERT INTO membership_plan 
       (plan_name, duration_months, price, description, features, max_trainer_sessions, is_active) 
       VALUES (?, ?, ?, ?, ?, ?, TRUE)`,
      [plan_name, duration_months, price, description, featuresJson, max_trainer_sessions || 0]
    );
    
    connection.release();
    res.json({ success: true, message: 'Plan added successfully', id: result.insertId });
  } catch (error) {
    console.error('Error adding plan:', error);
    res.status(500).json({ error: 'Failed to add plan: ' + error.message });
  }
});

// Add new payment
app.post('/api/payments', async (req, res) => {
  try {
    const { 
      gymmer_id, plan_id, amount, payment_method, 
      payment_date, payment_status 
    } = req.body;
    const connection = await pool.getConnection();
    
    const [result] = await connection.query(
      `INSERT INTO payments 
       (gymmer_id, plan_id, amount, payment_method, payment_date, payment_status) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [gymmer_id, plan_id, amount, payment_method || 'cash', 
       payment_date || new Date().toISOString().split('T')[0], payment_status || 'completed']
    );
    
    connection.release();
    res.json({ success: true, message: 'Payment recorded successfully', id: result.insertId });
  } catch (error) {
    console.error('Error adding payment:', error);
    res.status(500).json({ error: 'Failed to add payment: ' + error.message });
  }
});

// Add new attendance record
app.post('/api/attendance', async (req, res) => {
  try {
    const { 
      gymmer_id, date, check_in_time, check_out_time
    } = req.body;
    const connection = await pool.getConnection();
    
    // duration_minutes is auto-calculated by MySQL as a GENERATED column
    const [result] = await connection.query(
      `INSERT INTO attendance 
       (gymmer_id, date, check_in_time, check_out_time) 
       VALUES (?, ?, ?, ?)`,
      [gymmer_id, date || new Date().toISOString().split('T')[0], 
       check_in_time, check_out_time || null]
    );
    
    connection.release();
    res.json({ success: true, message: 'Attendance recorded successfully', id: result.insertId });
  } catch (error) {
    console.error('Error adding attendance:', error);
    res.status(500).json({ error: 'Failed to add attendance: ' + error.message });
  }
});

// ========================================
// PUT ENDPOINTS - UPDATE OPERATIONS
// ========================================

// Update member
app.put('/api/members/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body || {};
    const connection = await pool.getConnection();

    // Only allow member columns and skip blank strings so revisits/partial forms
    // cannot accidentally wipe existing values.
    const allowedFields = new Set([
      'username',
      'full_name',
      'email',
      'phone',
      'date_of_birth',
      'gender',
      'address',
      'emergency_contact',
      'emergency_phone',
      'plan_id',
      'trainer_id',
      'membership_start',
      'membership_end',
      'status'
    ]);

    const fields = Object.keys(updates).filter(key => {
      if (!allowedFields.has(key)) return false;
      const value = updates[key];

      // Allow explicit null for nullable FK fields.
      if ((key === 'trainer_id' || key === 'plan_id') && value === null) return true;

      // Prevent empty strings from clearing existing values.
      if (typeof value === 'string' && value.trim() === '') return false;

      return value !== undefined;
    });

    if (fields.length === 0) {
      connection.release();
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    const values = fields.map(key => updates[key]);
    const setClause = fields.map(field => `${field} = ?`).join(', ');
    
    await connection.query(
      `UPDATE gymmer SET ${setClause} WHERE gymmer_id = ?`,
      [...values, id]
    );
    
    connection.release();
    res.json({ success: true, message: 'Member updated successfully' });
  } catch (error) {
    console.error('Error updating member:', error);
    res.status(500).json({ error: 'Failed to update member: ' + error.message });
  }
});

// Update trainer
app.put('/api/trainers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    const connection = await pool.getConnection();

    const fields = Object.keys(updates).filter(key => key !== 'trainer_id');

    const values = fields.map(key => updates[key]);
    const setClause = fields.map(field => `${field} = ?`).join(', ');
    
    await connection.query(
      `UPDATE trainer SET ${setClause} WHERE trainer_id = ?`,
      [...values, id]
    );
    
    connection.release();
    res.json({ success: true, message: 'Trainer updated successfully' });
  } catch (error) {
    console.error('Error updating trainer:', error);
    res.status(500).json({ error: 'Failed to update trainer: ' + error.message });
  }
});

// Update membership plan
app.put('/api/plans/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    const connection = await pool.getConnection();
    
    const fields = Object.keys(updates).filter(key => key !== 'plan_id');
    const values = fields.map(key => key === 'features' ? JSON.stringify(updates[key]) : updates[key]);
    const setClause = fields.map(field => `${field} = ?`).join(', ');
    
    await connection.query(
      `UPDATE membership_plan SET ${setClause} WHERE plan_id = ?`,
      [...values, id]
    );
    
    connection.release();
    res.json({ success: true, message: 'Plan updated successfully' });
  } catch (error) {
    console.error('Error updating plan:', error);
    res.status(500).json({ error: 'Failed to update plan: ' + error.message });
  }
});

// Update payment
app.put('/api/payments/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    const connection = await pool.getConnection();
    
    const fields = Object.keys(updates).filter(key => key !== 'payment_id');
    const values = fields.map(key => updates[key]);
    const setClause = fields.map(field => `${field} = ?`).join(', ');
    
    await connection.query(
      `UPDATE payments SET ${setClause} WHERE payment_id = ?`,
      [...values, id]
    );
    
    connection.release();
    res.json({ success: true, message: 'Payment updated successfully' });
  } catch (error) {
    console.error('Error updating payment:', error);
    res.status(500).json({ error: 'Failed to update payment: ' + error.message });
  }
});

// Update attendance
app.put('/api/attendance/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    const connection = await pool.getConnection();
    
    // Exclude duration_minutes as it's a GENERATED column
    const fields = Object.keys(updates).filter(key => key !== 'attendance_id' && key !== 'duration_minutes');
    const values = fields.map(key => updates[key]);
    const setClause = fields.map(field => `${field} = ?`).join(', ');
    
    await connection.query(
      `UPDATE attendance SET ${setClause} WHERE attendance_id = ?`,
      [...values, id]
    );
    
    connection.release();
    res.json({ success: true, message: 'Attendance updated successfully' });
  } catch (error) {
    console.error('Error updating attendance:', error);
    res.status(500).json({ error: 'Failed to update attendance: ' + error.message });
  }
});

// ========================================
// DELETE ENDPOINTS - DELETE OPERATIONS
// ========================================

// Delete member (hard delete)
app.delete('/api/members/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    
    const [result] = await connection.query(
      `DELETE FROM gymmer WHERE gymmer_id = ?`,
      [id]
    );
    
    connection.release();
    if (!result.affectedRows) {
      return res.status(404).json({ error: 'Member not found' });
    }

    res.json({ success: true, message: 'Member deleted successfully' });
  } catch (error) {
    console.error('Error deleting member:', error);
    res.status(500).json({ error: 'Failed to delete member: ' + error.message });
  }
});

// Delete trainer (hard delete)
app.delete('/api/trainers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    
    const [result] = await connection.query(
      `DELETE FROM trainer WHERE trainer_id = ?`,
      [id]
    );
    
    connection.release();
    if (!result.affectedRows) {
      return res.status(404).json({ error: 'Trainer not found' });
    }

    res.json({ success: true, message: 'Trainer deleted successfully' });
  } catch (error) {
    console.error('Error deleting trainer:', error);
    res.status(500).json({ error: 'Failed to delete trainer: ' + error.message });
  }
});

// Delete membership plan (hard delete)
app.delete('/api/plans/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    
    const [result] = await connection.query(
      `DELETE FROM membership_plan WHERE plan_id = ?`,
      [id]
    );
    
    connection.release();
    if (!result.affectedRows) {
      return res.status(404).json({ error: 'Plan not found' });
    }

    res.json({ success: true, message: 'Plan deleted successfully' });
  } catch (error) {
    console.error('Error deleting plan:', error);
    if (error && error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(409).json({
        error: 'Cannot delete this plan because related payment records exist. Delete related payments first.'
      });
    }
    res.status(500).json({ error: 'Failed to delete plan: ' + error.message });
  }
});

// Delete payment (hard delete - use with caution)
app.delete('/api/payments/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    
    await connection.query(
      `DELETE FROM payments WHERE payment_id = ?`,
      [id]
    );
    
    connection.release();
    res.json({ success: true, message: 'Payment deleted successfully' });
  } catch (error) {
    console.error('Error deleting payment:', error);
    res.status(500).json({ error: 'Failed to delete payment: ' + error.message });
  }
});

// Delete attendance (hard delete)
app.delete('/api/attendance/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await pool.getConnection();
    
    await connection.query(
      `DELETE FROM attendance WHERE attendance_id = ?`,
      [id]
    );
    
    connection.release();
    res.json({ success: true, message: 'Attendance record deleted successfully' });
  } catch (error) {
    console.error('Error deleting attendance:', error);
    res.status(500).json({ error: 'Failed to delete attendance: ' + error.message });
  }
});

// Health check endpoint with live database status
app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    return res.status(200).json({
      status: 'Server is running',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    return res.status(503).json({
      status: 'Server is running',
      database: 'disconnected',
      dbError: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Start Server
const PORT = process.env.SERVER_PORT || 3001;
app.listen(PORT, () => {
  console.log(`
  ========================================
  GYM MANAGEMENT SYSTEM - SERVER RUNNING
  ========================================
  Server is running on: http://localhost:${PORT}
  
  📊 Dashboard & Stats:
  - GET  /api/health               (Health check)
  - GET  /api/dashboard/stats      (Dashboard statistics)
  - GET  /api/expiring-memberships (Expiring memberships)

  👥 Members API:
  - GET    /api/members            (Get all members)
  - GET    /api/members/:id        (Get member by ID)
  - POST   /api/members            (Add new member)
  - PUT    /api/members/:id        (Update member)
  - DELETE /api/members/:id        (Deactivate member)

  🏃 Trainers API:
  - GET    /api/trainers           (Get all trainers)
  - POST   /api/trainers           (Add new trainer)
  - PUT    /api/trainers/:id       (Update trainer)
  - DELETE /api/trainers/:id       (Deactivate trainer)

  📋 Plans API:
  - GET    /api/plans              (Get all plans)
  - POST   /api/plans              (Add new plan)
  - PUT    /api/plans/:id          (Update plan)
  - DELETE /api/plans/:id          (Deactivate plan)

  💳 Payments API:
  - GET    /api/payments           (Get all payments)
  - POST   /api/payments           (Record payment)
  - PUT    /api/payments/:id       (Update payment)
  - DELETE /api/payments/:id       (Delete payment)

  ✓ Attendance API:
  - GET    /api/attendance         (Get attendance records)
  - POST   /api/attendance         (Record attendance)
  - PUT    /api/attendance/:id     (Update attendance)
  - DELETE /api/attendance/:id     (Delete attendance)
  
  ========================================
  `);
});

module.exports = app;
