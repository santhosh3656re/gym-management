# Gym Management System - Quick Start Script (PowerShell)
# Run with: .\start.ps1

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  GYM MANAGEMENT SYSTEM - QUICK START" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "[✓] Node.js detected" -ForegroundColor Green
    Write-Host "    Version: $nodeVersion`n" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Node.js is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install from: https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if npm modules are installed
if (-Not (Test-Path "node_modules")) {
    Write-Host "[*] Installing npm dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "[✓] Dependencies installed`n" -ForegroundColor Green
}
else {
    Write-Host "[✓] npm modules already installed`n" -ForegroundColor Green
}

# Check .env file
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  CONFIGURATION CHECK" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

if (-Not (Test-Path ".env")) {
    Write-Host "[WARNING] .env file not found!" -ForegroundColor Yellow
    Write-Host "[*] Creating .env file with default values..." -ForegroundColor Yellow
    
    $envContent = @"
# MySQL Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password_here
DB_NAME=gym_management
DB_PORT=3306
DB_KEEP_ALIVE_MS=300000

# Server Configuration
SERVER_PORT=3001
NODE_ENV=development
"@
    
    Set-Content -Path ".env" -Value $envContent
    Write-Host "[!] .env file created" -ForegroundColor Yellow
    Write-Host "[!] Please edit .env with your MySQL credentials" -ForegroundColor Yellow
    Write-Host "[!] Then run this script again`n" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[✓] .env file found`n" -ForegroundColor Green

# Start the server
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  STARTING SERVER" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

Write-Host "Server will start on:" -ForegroundColor White
Write-Host "  http://localhost:3001" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access the dashboard at:" -ForegroundColor White
Write-Host "  http://localhost:3001/admin-dashboard-mysql.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Health Check:" -ForegroundColor White
Write-Host "  http://localhost:3001/api/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server`n" -ForegroundColor Yellow

npm start
