@echo off
REM Gym Management System - Quick Start Script
REM This script sets up and starts the application

echo.
echo ================================================
echo  GYM MANAGEMENT SYSTEM - QUICK START
echo ================================================
echo.

REM Check if Node.js is installed
node --version > nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo Please install Node.js from: https://nodejs.org/
    pause
    exit /b 1
)

echo [✓] Node.js detected
node --version
echo.

REM Check if npm modules are installed
if not exist "node_modules" (
    echo [*] Installing npm dependencies...
    call npm install
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
    echo [✓] Dependencies installed
) else (
    echo [✓] npm modules already installed
)

echo.
echo ================================================
echo  CONFIGURATION CHECK
echo ================================================
echo.

REM Check if .env file exists
if not exist ".env" (
    echo [WARNING] .env file not found!
    echo Creating .env file with default values...
    (
        echo # MySQL Database Configuration
        echo DB_HOST=localhost
        echo DB_USER=root
        echo DB_PASSWORD=your_password_here
        echo DB_NAME=gym_management
        echo DB_PORT=3306
        echo DB_KEEP_ALIVE_MS=300000
        echo.
        echo # Server Configuration
        echo SERVER_PORT=3001
        echo NODE_ENV=development
    ) > .env
    echo [!] Please edit .env file with your MySQL credentials
    echo [!] Then run this script again
    pause
    exit /b 1
)

echo [✓] .env file found

echo.
echo ================================================
echo  STARTING SERVER
echo ================================================
echo.
echo Server will start on: http://localhost:3001
echo.
echo Navigation:
echo   - Dashboard: http://localhost:3001/admin-dashboard-mysql.html
echo   - API Health: http://localhost:3001/api/health
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
call npm start
