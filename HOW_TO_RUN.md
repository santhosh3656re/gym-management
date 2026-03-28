# GYM Management System - Quick Start Guide

## 🚀 How to Run in Terminal

### Option 1: Quick Start (Recommended)
```powershell
# 1. Open PowerShell
# 2. Navigate to project folder
cd "e:\GYM Management"

# 3. Start the server
npm start
```

### Option 2: Using the Batch File
```powershell
# Simply double-click on start.bat in your project folder
# OR run in terminal:
.\start.bat
```

### Option 3: Using PowerShell Script
```powershell
# Run the PowerShell start script:
.\start.ps1
```

---

## 🌐 Access Your Dashboard

Once the server is running, open your browser and visit:

- **Combined Dashboard (MySQL):** http://localhost:3001/combined-dashboard-mysql.html
- **Admin Dashboard:** http://localhost:3001/admin-dashboard-mysql.html
- **Gymmer Dashboard:** http://localhost:3001/gymmer-dashboard.html

---

## 🛑 How to Stop the Server

Press `Ctrl + C` in the terminal where the server is running.

Or run this command in PowerShell:
```powershell
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
```

---

## ✅ Verify Everything is Working

### 1. Check if server is running:
```powershell
Invoke-WebRequest "http://localhost:3001/api/health" -UseBasicParsing
```

You should see:
```json
{"status":"Server is running","timestamp":"2026-02-15T..."}
```

### 2. Check database connection:
```powershell
Invoke-WebRequest "http://localhost:3001/api/dashboard/stats" -UseBasicParsing
```

You should see statistics like:
```json
{"totalMembers":6,"totalRevenue":4499,"todayAttendance":1,"totalTrainers":7}
```

---

## 🔧 Troubleshooting

### Problem: Port 3001 already in use
```powershell
# Kill any process using the port
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force

# Then start again
npm start
```

### Problem: Database connection error
```powershell
# Make sure MySQL is running
# Check your .env file has the correct password:
# DB_PASSWORD=S@nthosh8124
```

### Problem: npm command not found
```powershell
# Install Node.js from https://nodejs.org/
# Then restart PowerShell
```

---

## 📊 Quick API Tests

### Get all members:
```powershell
Invoke-WebRequest "http://localhost:3001/api/members" -UseBasicParsing | ConvertFrom-Json
```

### Get all trainers:
```powershell
Invoke-WebRequest "http://localhost:3001/api/trainers" -UseBasicParsing | ConvertFrom-Json
```

### Get dashboard stats:
```powershell
Invoke-WebRequest "http://localhost:3001/api/dashboard/stats" -UseBasicParsing | ConvertFrom-Json
```

### Add a new member:
```powershell
$memberData = @{
    username = "newuser"
    full_name = "New User"
    email = "newuser@email.com"
    phone = "9876543210"
    date_of_birth = "1995-01-15"
    gender = "male"
    plan_id = 1
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:3001/api/members" `
    -Method POST `
    -Body $memberData `
    -ContentType "application/json" `
    -UseBasicParsing
```

---

## 🎯 Common Tasks

### Start server in background (doesn't block terminal):
```powershell
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'e:\GYM Management'; npm start" -WindowStyle Minimized
```

### View server logs:
The logs will appear in the terminal where you ran `npm start`

### Restart server:
```powershell
# Stop server
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force

# Wait a moment
Start-Sleep -Seconds 2

# Start server
cd "e:\GYM Management"
npm start
```

---

## 📁 Project Structure

```
E:\GYM Management\
├── server.js              # Main server file
├── package.json           # Dependencies
├── .env                   # Database configuration
├── start.bat              # Windows batch script
├── start.ps1              # PowerShell script
├── files/
│   ├── schema.sql         # Database schema
│   ├── combined-dashboard-mysql.html
│   ├── admin-dashboard-mysql.html
│   └── gymmer-dashboard.html
├── API_EXAMPLES.md        # API documentation
└── API_REFERENCE.md       # API reference
```

---

## 🔐 Environment Variables (.env file)

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=S@nthosh8124
DB_NAME=gym_management
DB_PORT=3306
DB_KEEP_ALIVE_MS=300000
SERVER_PORT=3001
NODE_ENV=development
```

---

## 💡 Tips

1. **Always run `npm start` from the project directory**: `e:\GYM Management`
2. **Keep the terminal open** while using the application
3. **The server must be running** for the dashboards to work
4. **Port 3001** must be available (not used by another application)
5. **MySQL must be running** and accessible

---

## 🎉 You're Ready!

Your GYM Management System is now running and ready to use!

**Next Steps:**
- Open http://localhost:3001/combined-dashboard-mysql.html
- Switch between Admin and Gymmer views
- Add members, trainers, track attendance, and manage payments!
