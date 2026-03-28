# GYM Management System - API Examples

## Base URL
```
http://localhost:3001/api
```

---

## 👥 MEMBERS API

### Get All Members
```bash
GET /api/members
```

### Get Member by ID
```bash
GET /api/members/1
```

### Add New Member
```bash
POST /api/members
Content-Type: application/json

{
  "username": "newuser",
  "full_name": "John Doe",
  "email": "john.doe@example.com",
  "phone": "9876543210",
  "date_of_birth": "1995-05-15",
  "gender": "male",
  "plan_id": 1,
  "trainer_id": 1,
  "address": "123 Main St",
  "emergency_contact": "Jane Doe",
  "emergency_phone": "9876543211",
  "membership_start": "2026-02-15",
  "membership_end": "2026-03-15"
}
```

### Update Member
```bash
PUT /api/members/1
Content-Type: application/json

{
  "phone": "9999999999",
  "plan_id": 3,
  "trainer_id": 2
}
```

### Delete Member (Soft Delete)
```bash
DELETE /api/members/1
```

---

## 🏃 TRAINERS API

### Get All Trainers
```bash
GET /api/trainers
```

### Add New Trainer
```bash
POST /api/trainers
Content-Type: application/json

{
  "full_name": "Sarah Johnson",
  "email": "sarah.j@gym.com",
  "phone": "9998887777",
  "specialization": "Yoga & Flexibility",
  "certification": "RYT-500",
  "experience_years": 3,
  "hourly_rate": 1200,
  "bio": "Certified yoga instructor with 3 years experience",
  "joined_date": "2026-02-15"
}
```

### Update Trainer
```bash
PUT /api/trainers/1
Content-Type: application/json

{
  "hourly_rate": 1500,
  "specialization": "Advanced Yoga & Meditation"
}
```

### Delete Trainer (Soft Delete)
```bash
DELETE /api/trainers/1
```

---

## 📋 MEMBERSHIP PLANS API

### Get All Plans
```bash
GET /api/plans
```

### Add New Plan
```bash
POST /api/plans
Content-Type: application/json

{
  "plan_name": "Weekend Warrior",
  "duration_months": 1,
  "price": 1299,
  "description": "Weekend access membership",
  "features": ["Weekend Gym Access", "Locker Facility", "Group Classes"],
  "max_trainer_sessions": 2
}
```

### Update Plan
```bash
PUT /api/plans/1
Content-Type: application/json

{
  "price": 1099,
  "max_trainer_sessions": 3
}
```

### Delete Plan (Soft Delete)
```bash
DELETE /api/plans/1
```

---

## 💳 PAYMENTS API

### Get All Payments
```bash
GET /api/payments
```

### Add New Payment
```bash
POST /api/payments
Content-Type: application/json

{
  "gymmer_id": 1,
  "plan_id": 3,
  "amount": 4499,
  "payment_method": "upi",
  "payment_date": "2026-02-15",
  "payment_status": "completed"
}
```

### Update Payment
```bash
PUT /api/payments/1
Content-Type: application/json

{
  "payment_status": "completed"
}
```

### Delete Payment (Hard Delete)
```bash
DELETE /api/payments/1
```

---

## ✓ ATTENDANCE API

### Get All Attendance Records
```bash
GET /api/attendance
```

### Add Attendance Record
```bash
POST /api/attendance
Content-Type: application/json

{
  "gymmer_id": 1,
  "date": "2026-02-15",
  "check_in_time": "2026-02-15 08:30:00",
  "check_out_time": "2026-02-15 10:00:00"
}
```
**Note:** `duration_minutes` is auto-calculated by the database based on check-in and check-out times.

### Update Attendance
```bash
PUT /api/attendance/1
Content-Type: application/json

{
  "check_out_time": "2026-02-15 11:00:00"
}
```

### Delete Attendance (Hard Delete)
```bash
DELETE /api/attendance/1
```

---

## 📊 DASHBOARD & STATS API

### Get Dashboard Statistics
```bash
GET /api/dashboard/stats
```
Returns:
```json
{
  "totalMembers": 5,
  "totalRevenue": 12450,
  "todayAttendance": 3,
  "totalTrainers": 4
}
```

### Get Expiring Memberships (Next 7 Days)
```bash
GET /api/expiring-memberships
```

### Health Check
```bash
GET /api/health
```

---

## PowerShell Examples

### Add Member (PowerShell)
```powershell
$memberData = @{
    username = "johndoe"
    full_name = "John Doe"
    email = "john@example.com"
    phone = "9876543210"
    date_of_birth = "1995-05-15"
    gender = "male"
    plan_id = 1
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:3001/api/members" `
    -Method POST `
    -Body $memberData `
    -ContentType "application/json"
```

### Add Trainer (PowerShell)
```powershell
$trainerData = @{
    full_name = "Sarah Johnson"
    email = "sarah@gym.com"
    phone = "9998887777"
    specialization = "Yoga"
    experience_years = 3
    hourly_rate = 1200
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:3001/api/trainers" `
    -Method POST `
    -Body $trainerData `
    -ContentType "application/json"
```

### Add Attendance (PowerShell)
```powershell
$attendanceData = @{
    gymmer_id = 1
    date = "2026-02-15"
    check_in_time = "2026-02-15 08:30:00"
    check_out_time = "2026-02-15 10:00:00"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:3001/api/attendance" `
    -Method POST `
    -Body $attendanceData `
    -ContentType "application/json"
```

---

## JavaScript/Fetch Examples

### Add Member (JavaScript)
```javascript
const memberData = {
    username: "johndoe",
    full_name: "John Doe",
    email: "john@example.com",
    phone: "9876543210",
    date_of_birth: "1995-05-15",
    gender: "male",
    plan_id: 1
};

fetch('http://localhost:3001/api/members', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(memberData)
})
.then(response => response.json())
.then(data => console.log(data));
```

### Update Member (JavaScript)
```javascript
const updates = {
    phone: "9999999999",
    plan_id: 3
};

fetch('http://localhost:3001/api/members/1', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(updates)
})
.then(response => response.json())
.then(data => console.log(data));
```

---

## Error Handling

All endpoints return consistent error responses:

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "id": 5
}
```

### Error Response
```json
{
  "error": "Failed to add member: Duplicate entry 'email@example.com' for key 'gymmer.email'"
}
```

---

## Notes

1. **Soft Deletes**: Members, Trainers, and Plans use soft deletes (status change to inactive/unavailable)
2. **Hard Deletes**: Payments and Attendance use hard deletes (permanent removal)
3. **Auto-Generated Fields**:
   - `duration_minutes` in attendance is auto-calculated
   - `created_at` and `updated_at` are auto-managed by MySQL
4. **Password Hashing**: Member passwords are automatically hashed using SHA-256
5. **Validation**: Email and phone uniqueness is enforced by the database

---

## Testing All Endpoints

Run this PowerShell script to test all endpoints:

```powershell
# Test Members
Invoke-WebRequest "http://localhost:3001/api/members"

# Test Trainers
Invoke-WebRequest "http://localhost:3001/api/trainers"

# Test Plans
Invoke-WebRequest "http://localhost:3001/api/plans"

# Test Payments
Invoke-WebRequest "http://localhost:3001/api/payments"

# Test Attendance
Invoke-WebRequest "http://localhost:3001/api/attendance"

# Test Dashboard Stats
Invoke-WebRequest "http://localhost:3001/api/dashboard/stats"
```
