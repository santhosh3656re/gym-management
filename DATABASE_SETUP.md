# GYM Management System - MySQL Database Integration Guide

## Overview
This guide explains how to set up and run the Gym Management System with a MySQL database backend and web frontend.

## Prerequisites
- **Node.js** (v14 or higher) - [Download](https://nodejs.org/)
- **MySQL Server** (v8.0 or higher) - [Download](https://dev.mysql.com/downloads/mysql/)
- A command terminal (PowerShell, CMD, or Terminal)

## Installation Steps

### 1. Install Node.js Dependencies
```bash
cd "e:\GYM Management"
npm install
```

This installs:
- **express** - Web server framework
- **mysql2** - MySQL database driver
- **cors** - Cross-origin resource sharing
- **dotenv** - Environment variable management
- **body-parser** - JSON body parsing

### 2. Create MySQL Database
Open MySQL Workbench or MySQL Command Line and run:

```bash
mysql -u root -p
```

For a first-time setup with sample data (this resets existing DB), run:
```bash
source "e:\GYM Management\files\schema.sql"
```

Or copy-paste the entire schema.sql content directly into MySQL.

### Safe Import (Keeps Existing Data)
For day-to-day use, always run the safe script below. It keeps your current data and can be re-run safely.

```bash
source "e:\GYM Management\files\schema-safe.sql"
```

`schema-safe.sql` does not drop the database.

Important:
- Use `schema.sql` only when you intentionally want a full reset.
- Use `schema-safe.sql` for normal updates so your project stays linked to the same database data.

### 3. Configure Database Connection
Edit the `.env` file in the root directory:

```env
# MySQL Database Configuration
DB_HOST=localhost        # Your MySQL server address
DB_USER=root             # Your MySQL username
DB_PASSWORD=your_password_here  # Your MySQL password
DB_NAME=gym_management   # Database name (don't change)
DB_PORT=3306             # MySQL port (default: 3306)

# Server Configuration
SERVER_PORT=3001         # Node.js server port
NODE_ENV=development     # Environment
```

**Important:** Update `DB_PASSWORD` with your actual MySQL password.

### 4. Start the Backend Server
```bash
npm start
```

You should see output like:
```
========================================
GYM MANAGEMENT SYSTEM - SERVER RUNNING
========================================
Server is running on: http://localhost:3001

Available API Endpoints:
- GET  /api/members              (Get all members)
- GET  /api/members/:id          (Get member details)
- GET  /api/trainers             (Get all trainers)
- GET  /api/plans                (Get membership plans)
- GET  /api/attendance           (Get attendance records)
- GET  /api/payments             (Get payments)
- GET  /api/dashboard/stats      (Get dashboard statistics)
- GET  /api/expiring-memberships (Get expiring memberships)
- POST /api/members              (Add new member)
- GET  /api/health               (Health check)

========================================
```

### 5. Access the Web Dashboard
Open your web browser and go to:
```
http://localhost:3001/admin-dashboard-mysql.html
```

## Features

### Dashboard
- **Real-time statistics** showing:
  - Total active members
  - Monthly revenue
  - Today's attendance count
  - Active trainers
- **Expiring memberships** alert (next 7 days)
- **Recent payments** view
- **Recent attendance** tracking

### Navigation Sections
1. **Dashboard** - Overview and key metrics
2. **Members** - Complete member list with details
3. **Trainers** - Trainer profiles and availability
4. **Payments** - Payment history and status
5. **Attendance** - Check-in/check-out records

### Database Indicator
A status indicator in the bottom-right corner shows:
- **Green dot** - Database connected ✓
- **Red dot** - Database disconnected ✗

## API Endpoints

### Members
```
GET /api/members              - Get all members
GET /api/members/:id          - Get specific member details
POST /api/members             - Add new member
```

### Trainers
```
GET /api/trainers             - Get all trainers
```

### Plans
```
GET /api/plans                - Get all active membership plans
```

### Attendance
```
GET /api/attendance           - Get attendance records
```

### Payments
```
GET /api/payments             - Get all payments
```

### Dashboard
```
GET /api/dashboard/stats      - Get dashboard statistics
GET /api/expiring-memberships - Get members with expiring memberships
```

### Health Check
```
GET /api/health               - Check if server is running
```

## Sample Data

The `schema.sql` file includes sample data:
- **5 Admin/Manager accounts**
- **4 Membership plans** (Basic, Standard, Premium, Elite)
- **4 Trainers** (Rajesh, Priya, Vikram, Anjali)
- **5 Members** with complete profiles
- **Sample attendance, payments, and workout records**

## Troubleshooting

### "Cannot connect to database"
1. Ensure MySQL is running
2. Check DB_HOST, DB_USER, DB_PASSWORD in `.env`
3. Verify the database `gym_management` exists
4. Try: `mysql -u root -p` to test connection

### "Port 3001 already in use"
1. Change `SERVER_PORT` in `.env` to another port (e.g., 3002)
2. Restart Node.js server

### "Module not found"
1. Delete `node_modules` folder
2. Delete `package-lock.json`
3. Run `npm install` again

### "CORS error"
1. Ensure server is running on http://localhost:3001
2. Check browser console for specific error messages
3. Verify API endpoints are correct

## Database Schema Overview

### Main Tables
- **admin** - System administrators
- **gymmer** - Gym members/customers
- **trainer** - Personal trainers
- **membership_plan** - Membership packages
- **payments** - Payment records
- **attendance** - Check-in/out records
- **equipment** - Gym equipment inventory
- **workout_plan** - Member workout schedules
- **diet_plan** - Member diet plans
- **progress_tracking** - Member fitness progress

### Views (Pre-built Queries)
- `v_active_members` - Active members with plan details
- `v_monthly_revenue` - Revenue reports
- `v_attendance_summary` - Attendance statistics
- `v_expiring_memberships` - Members expiring soon

## Next Steps

1. **Extend the API** - Add more endpoints for additional features
2. **Add Authentication** - Implement login/logout functionality
3. **Create Member Dashboard** - Build a separate member-facing interface
4. **Add Charts** - Visualize statistics with Chart.js
5. **Mobile App** - Create a mobile-friendly version

## File Structure
```
GYM Management/
├── server.js                          # Main Node.js/Express server
├── package.json                       # Node dependencies
├── .env                               # Database configuration
├── files/
│   ├── schema.sql                     # MySQL database schema
│   ├── admin-dashboard-mysql.html     # NEW: MySQL-powered dashboard
│   ├── admin-dashboard.html           # Original Firebase version
│   ├── combined-dashboard.html        # Combined view
│   ├── gymmer-dashboard.html          # Member dashboard
│   └── [other files]
└── README.md
```

## Support
For issues or questions, check:
1. Browser console (F12) for error messages
2. Server terminal output for backend errors
3. MySQL error logs
4. Verify all connections in `.env` file

---
**Created:** February 2026
**Status:** Database Integration Complete ✓
