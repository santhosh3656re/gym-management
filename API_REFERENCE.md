# GYM Management System - API Reference Guide

**Base URL:** `http://localhost:3001/api`

## Quick Start

The backend server provides RESTful API endpoints to access the MySQL database. All responses are in JSON format.

### Health Check
```
GET /api/health

Response:
{
  "status": "Server is running",
  "timestamp": "2026-02-15T10:30:00.000Z"
}
```

---

## Members Endpoints

### Get All Members
```
GET /api/members

Returns: Array of member objects with plan and trainer details
Limit: No limit (returns all members)

Response Example:
[
  {
    "gymmer_id": 1,
    "full_name": "Rahul Mehta",
    "email": "rahul.m@email.com",
    "phone": "9876501234",
    "plan_name": "Premium Half-Yearly",
    "price": 4499.00,
    "status": "active",
    "membership_start": "2025-11-01",
    "membership_end": "2026-05-01",
    "trainer_name": "Rajesh Kumar"
  }
]
```

### Get Member Details
```
GET /api/members/:id

Parameters:
  - id: Member ID (gymmer_id)

Returns: Single member object with profile and fitness data

Response Example:
{
  "gymmer_id": 1,
  "full_name": "Rahul Mehta",
  "email": "rahul.m@email.com",
  "phone": "9876501234",
  "status": "active",
  "height_cm": 175.0,
  "weight_kg": 78.5,
  "bmi": 25.6,
  "fitness_goal": "muscle_gain",
  "trainer_name": "Rajesh Kumar"
}
```

### Add New Member
```
POST /api/members

Body (JSON):
{
  "username": "new_user",
  "full_name": "New Member Name",
  "email": "newuser@email.com",
  "phone": "9876543210",
  "date_of_birth": "1990-05-15",
  "gender": "male",
  "plan_id": 3
}

Returns:
{
  "success": true,
  "message": "Member added successfully"
}
```

---

## Trainers Endpoints

### Get All Trainers
```
GET /api/trainers

Returns: Array of available trainers

Response Example:
[
  {
    "trainer_id": 1,
    "full_name": "Rajesh Kumar",
    "email": "rajesh.trainer@gymfit.com",
    "phone": "9123456780",
    "specialization": "Strength Training",
    "certification": "ACE Certified Personal Trainer",
    "experience_years": 5,
    "hourly_rate": 500.00,
    "is_available": true,
    "joined_date": "2021-01-15"
  }
]
```

---

## Membership Plans Endpoints

### Get All Active Plans
```
GET /api/plans

Returns: Array of active membership plans sorted by price

Response Example:
[
  {
    "plan_id": 1,
    "plan_name": "Basic Monthly",
    "duration_months": 1,
    "price": 999.00,
    "description": "Basic gym access with equipment usage",
    "features": ["Gym Access", "Locker Facility", "Shower"],
    "max_trainer_sessions": 0,
    "is_active": true
  },
  {
    "plan_id": 4,
    "plan_name": "Elite Annual",
    "duration_months": 12,
    "price": 7999.00,
    "description": "Elite membership with all facilities",
    "features": ["Gym Access", "Unlimited Trainer Sessions", "Nutritionist Consultation"],
    "max_trainer_sessions": 999,
    "is_active": true
  }
]
```

---

## Attendance Endpoints

### Get Attendance Records
```
GET /api/attendance

Returns: Array of recent attendance records (max 100)
Ordered by: Date DESC, Check-in time DESC

Response Example:
[
  {
    "attendance_id": 1,
    "gymmer_id": 1,
    "full_name": "Rahul Mehta",
    "check_in_time": "2026-02-15T06:30:00",
    "check_out_time": "2026-02-15T08:00:00",
    "date": "2026-02-15",
    "duration_minutes": 90
  }
]
```

---

## Payments Endpoints

### Get All Payments
```
GET /api/payments

Returns: Array of payment records (max 100)
Ordered by: Payment date DESC

Response Example:
[
  {
    "payment_id": 1,
    "gymmer_id": 1,
    "full_name": "Rahul Mehta",
    "plan_name": "Premium Half-Yearly",
    "amount": 4499.00,
    "payment_date": "2025-11-01",
    "payment_method": "card",
    "payment_status": "completed",
    "billing_month": "2025-11"
  }
]
```

---

## Dashboard Statistics Endpoints

### Get Dashboard Statistics
```
GET /api/dashboard/stats

Returns: Summary statistics for the dashboard

Response Example:
{
  "totalMembers": 5,
  "totalRevenue": 24996.00,
  "todayAttendance": 4,
  "totalTrainers": 4
}
```

---

## Membership Management Endpoints

### Get Expiring Memberships
```
GET /api/expiring-memberships

Returns: Members with memberships expiring within 7 days
Ordered by: Membership end date ASC

Response Example:
[
  {
    "gymmer_id": 4,
    "full_name": "Kavya Nair",
    "email": "kavya.n@email.com",
    "phone": "9876504567",
    "plan_name": "Basic Monthly",
    "membership_end": "2026-02-10",
    "days_remaining": -5
  }
]
```

---

## Common Response Codes

| Code | Meaning |
|------|---------|
| 200 | Success - Request completed successfully |
| 400 | Bad Request - Invalid parameters |
| 404 | Not Found - Resource doesn't exist |
| 500 | Server Error - Database or server issue |

---

## Usage Examples

### Using JavaScript Fetch
```javascript
// Get all members
fetch('http://localhost:3001/api/members')
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));

// Get specific member
fetch('http://localhost:3001/api/members/1')
  .then(response => response.json())
  .then(member => console.log(member));

// Add new member
fetch('http://localhost:3001/api/members', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'john_doe',
    full_name: 'John Doe',
    email: 'john@email.com',
    phone: '9876543210',
    date_of_birth: '1990-01-15',
    gender: 'male',
    plan_id: 1
  })
})
.then(response => response.json())
.then(data => console.log(data));
```

### Using cURL
```bash
# Get all members
curl http://localhost:3001/api/members

# Get specific member
curl http://localhost:3001/api/members/1

# Get trainers
curl http://localhost:3001/api/trainers

# Get dashboard stats
curl http://localhost:3001/api/dashboard/stats

# Add new member (Windows may need different escaping)
curl -X POST http://localhost:3001/api/members \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"john\",\"full_name\":\"John\",\"email\":\"john@email.com\",\"phone\":\"9876543210\",\"date_of_birth\":\"1990-01-15\",\"gender\":\"male\",\"plan_id\":1}"
```

---

## CORS Headers

The API supports CORS requests from any origin:
```
Access-Control-Allow-Origin: *
```

---

## Database Tables Reference

### Table: gymmer (Members)
- gymmer_id (INT) - Primary Key
- username (VARCHAR) - Unique username
- full_name (VARCHAR) - Full name
- email (VARCHAR) - Email address
- phone (VARCHAR) - Phone number
- status (ENUM) - 'active', 'expired', 'suspended', 'inactive'
- plan_id (INT) - Foreign Key to membership_plan
- trainer_id (INT) - Foreign Key to trainer
- membership_end (DATE) - Membership expiration date

### Table: trainer (Trainers)
- trainer_id (INT) - Primary Key
- full_name (VARCHAR) - Trainer's name
- specialization (VARCHAR) - Training specialty
- hourly_rate (DECIMAL) - Rate per hour
- is_available (BOOLEAN) - Availability status

### Table: membership_plan (Plans)
- plan_id (INT) - Primary Key
- plan_name (VARCHAR) - Plan name
- price (DECIMAL) - Plan price
- duration_months (INT) - Duration in months

### Table: payments (Payments)
- payment_id (INT) - Primary Key
- gymmer_id (INT) - Foreign Key to gymmer
- amount (DECIMAL) - Payment amount
- payment_date (DATE) - Payment date
- payment_status (ENUM) - 'pending', 'completed', 'failed', 'refunded'

### Table: attendance (Attendance)
- attendance_id (INT) - Primary Key
- gymmer_id (INT) - Foreign Key to gymmer
- check_in_time (DATETIME) - Check-in timestamp
- check_out_time (DATETIME) - Check-out timestamp
- date (DATE) - Attendance date

---

**Last Updated:** February 15, 2026
**API Version:** 1.0
**Status:** Production Ready ✓
