-- ===================================================
-- GYM MANAGEMENT SYSTEM - DATABASE SCHEMA
-- ===================================================
-- Created: 2026
-- Database: MySQL 8.0+
-- ===================================================

CREATE DATABASE IF NOT EXISTS gym_management;
USE gym_management;

-- ===================================================
-- ADMIN MODULE TABLES
-- ===================================================

-- Admin table for system administrators
CREATE TABLE IF NOT EXISTS admin (
    admin_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    role ENUM('super_admin', 'manager', 'staff') DEFAULT 'staff',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_username (username),
    INDEX idx_email (email)
);

-- Membership Plans
CREATE TABLE IF NOT EXISTS membership_plan (
    plan_id INT PRIMARY KEY AUTO_INCREMENT,
    plan_name VARCHAR(100) NOT NULL,
    duration_months INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    features JSON,
    max_trainer_sessions INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_plan_name (plan_name)
);

-- Trainers
CREATE TABLE IF NOT EXISTS trainer (
    trainer_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) NOT NULL,
    specialization VARCHAR(100),
    certification VARCHAR(200),
    experience_years INT DEFAULT 0,
    hourly_rate DECIMAL(10, 2),
    photo_url VARCHAR(255),
    bio TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    joined_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_specialization (specialization)
);

-- Gymmers/Members
CREATE TABLE IF NOT EXISTS gymmer (
    gymmer_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) NOT NULL,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other') NOT NULL,
    address TEXT,
    emergency_contact VARCHAR(100),
    emergency_phone VARCHAR(15),
    photo_url VARCHAR(255),
    plan_id INT,
    trainer_id INT,
    join_date DATE NOT NULL,
    membership_start DATE,
    membership_end DATE,
    status ENUM('active', 'expired', 'suspended', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES membership_plan(plan_id) ON DELETE SET NULL,
    FOREIGN KEY (trainer_id) REFERENCES trainer(trainer_id) ON DELETE SET NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_membership_end (membership_end)
);

-- Gymmer Access Logs
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
);

-- Gymmer Profile (Health & Fitness Data)
CREATE TABLE IF NOT EXISTS gymmer_profile (
    profile_id INT PRIMARY KEY AUTO_INCREMENT,
    gymmer_id INT UNIQUE NOT NULL,
    height_cm DECIMAL(5, 2),
    weight_kg DECIMAL(5, 2),
    bmi DECIMAL(4, 2) GENERATED ALWAYS AS (weight_kg / ((height_cm/100) * (height_cm/100))) STORED,
    blood_group VARCHAR(5),
    medical_conditions TEXT,
    fitness_goal ENUM('weight_loss', 'muscle_gain', 'endurance', 'general_fitness', 'strength') DEFAULT 'general_fitness',
    target_weight_kg DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (gymmer_id) REFERENCES gymmer(gymmer_id) ON DELETE CASCADE
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    gymmer_id INT NOT NULL,
    plan_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method ENUM('cash', 'card', 'upi', 'net_banking', 'other') DEFAULT 'cash',
    transaction_id VARCHAR(100),
    payment_status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'completed',
    billing_month VARCHAR(7), -- YYYY-MM format
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (gymmer_id) REFERENCES gymmer(gymmer_id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES membership_plan(plan_id) ON DELETE RESTRICT,
    INDEX idx_gymmer_id (gymmer_id),
    INDEX idx_payment_date (payment_date),
    INDEX idx_payment_status (payment_status)
);

-- Attendance
CREATE TABLE IF NOT EXISTS attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    gymmer_id INT NOT NULL,
    check_in_time DATETIME NOT NULL,
    check_out_time DATETIME,
    date DATE NOT NULL,
    duration_minutes INT GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, check_in_time, check_out_time)) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (gymmer_id) REFERENCES gymmer(gymmer_id) ON DELETE CASCADE,
    INDEX idx_gymmer_date (gymmer_id, date),
    INDEX idx_date (date)
);

-- Equipment
CREATE TABLE IF NOT EXISTS equipment (
    equipment_id INT PRIMARY KEY AUTO_INCREMENT,
    equipment_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    quantity INT DEFAULT 1,
    purchase_date DATE,
    price DECIMAL(10, 2),
    condition_status ENUM('excellent', 'good', 'fair', 'poor', 'maintenance_required') DEFAULT 'good',
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    location VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_condition (condition_status)
);

-- ===================================================
-- GYMMER MODULE TABLES
-- ===================================================

-- Workout Plans
CREATE TABLE IF NOT EXISTS workout_plan (
    workout_id INT PRIMARY KEY AUTO_INCREMENT,
    gymmer_id INT NOT NULL,
    trainer_id INT,
    plan_name VARCHAR(100) NOT NULL,
    day_of_week ENUM('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday') NOT NULL,
    exercises JSON NOT NULL, -- Array of {exercise_name, sets, reps, rest_time}
    duration_minutes INT DEFAULT 60,
    difficulty ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    is_active BOOLEAN DEFAULT TRUE,
    start_date DATE NOT NULL,
    end_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (gymmer_id) REFERENCES gymmer(gymmer_id) ON DELETE CASCADE,
    FOREIGN KEY (trainer_id) REFERENCES trainer(trainer_id) ON DELETE SET NULL,
    INDEX idx_gymmer_active (gymmer_id, is_active)
);

-- Diet Plans
CREATE TABLE IF NOT EXISTS diet_plan (
    diet_id INT PRIMARY KEY AUTO_INCREMENT,
    gymmer_id INT NOT NULL,
    trainer_id INT,
    plan_name VARCHAR(100) NOT NULL,
    meal_type ENUM('breakfast', 'lunch', 'dinner', 'snack_1', 'snack_2') NOT NULL,
    meal_items JSON NOT NULL, -- Array of {item_name, quantity, calories, protein}
    total_calories INT,
    total_protein_g DECIMAL(6, 2),
    total_carbs_g DECIMAL(6, 2),
    total_fat_g DECIMAL(6, 2),
    is_active BOOLEAN DEFAULT TRUE,
    start_date DATE NOT NULL,
    end_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (gymmer_id) REFERENCES gymmer(gymmer_id) ON DELETE CASCADE,
    FOREIGN KEY (trainer_id) REFERENCES trainer(trainer_id) ON DELETE SET NULL,
    INDEX idx_gymmer_active (gymmer_id, is_active)
);

-- Progress Tracking
CREATE TABLE IF NOT EXISTS progress_tracking (
    progress_id INT PRIMARY KEY AUTO_INCREMENT,
    gymmer_id INT NOT NULL,
    record_date DATE NOT NULL,
    weight_kg DECIMAL(5, 2),
    body_fat_percentage DECIMAL(4, 2),
    muscle_mass_kg DECIMAL(5, 2),
    chest_cm DECIMAL(5, 2),
    waist_cm DECIMAL(5, 2),
    hips_cm DECIMAL(5, 2),
    biceps_cm DECIMAL(5, 2),
    thighs_cm DECIMAL(5, 2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (gymmer_id) REFERENCES gymmer(gymmer_id) ON DELETE CASCADE,
    INDEX idx_gymmer_date (gymmer_id, record_date)
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    user_type ENUM('admin', 'gymmer') NOT NULL,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type ENUM('payment_due', 'membership_expiry', 'attendance_alert', 'trainer_update', 'general') DEFAULT 'general',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_type, user_id, is_read)
);

-- Trainer-Gymmer Sessions
CREATE TABLE IF NOT EXISTS training_sessions (
    session_id INT PRIMARY KEY AUTO_INCREMENT,
    trainer_id INT NOT NULL,
    gymmer_id INT NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    session_type ENUM('personal_training', 'group_class', 'consultation') DEFAULT 'personal_training',
    status ENUM('scheduled', 'completed', 'cancelled', 'no_show') DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trainer_id) REFERENCES trainer(trainer_id) ON DELETE CASCADE,
    FOREIGN KEY (gymmer_id) REFERENCES gymmer(gymmer_id) ON DELETE CASCADE,
    INDEX idx_trainer_date (trainer_id, session_date),
    INDEX idx_gymmer_date (gymmer_id, session_date)
);

-- ===================================================
-- INDEXES FOR PERFORMANCE
-- ===================================================

-- Composite indexes for common queries
SET @idx_exists = (
        SELECT COUNT(1)
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
            AND table_name = 'gymmer'
            AND index_name = 'idx_gymmer_plan_status'
);
SET @sql = IF(@idx_exists = 0, 'CREATE INDEX idx_gymmer_plan_status ON gymmer(plan_id, status)', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
        SELECT COUNT(1)
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
            AND table_name = 'payments'
            AND index_name = 'idx_payment_gymmer_date'
);
SET @sql = IF(@idx_exists = 0, 'CREATE INDEX idx_payment_gymmer_date ON payments(gymmer_id, payment_date)', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
        SELECT COUNT(1)
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
            AND table_name = 'attendance'
            AND index_name = 'idx_attendance_date_gymmer'
);
SET @sql = IF(@idx_exists = 0, 'CREATE INDEX idx_attendance_date_gymmer ON attendance(date, gymmer_id)', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ===================================================
-- VIEWS FOR REPORTING
-- ===================================================

-- Active Members with Plan Details
DROP VIEW IF EXISTS v_active_members;
CREATE VIEW v_active_members AS
SELECT 
    g.gymmer_id,
    g.full_name,
    g.email,
    g.phone,
    mp.plan_name,
    mp.price,
    g.membership_start,
    g.membership_end,
    DATEDIFF(g.membership_end, CURDATE()) AS days_remaining,
    t.full_name AS trainer_name,
    g.status
FROM gymmer g
LEFT JOIN membership_plan mp ON g.plan_id = mp.plan_id
LEFT JOIN trainer t ON g.trainer_id = t.trainer_id
WHERE g.status = 'active';

-- Monthly Revenue Report
DROP VIEW IF EXISTS v_monthly_revenue;
CREATE VIEW v_monthly_revenue AS
SELECT 
    DATE_FORMAT(payment_date, '%Y-%m') AS month,
    COUNT(payment_id) AS total_transactions,
    SUM(amount) AS total_revenue,
    AVG(amount) AS average_payment
FROM payments
WHERE payment_status = 'completed'
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY month DESC;

-- Attendance Summary
DROP VIEW IF EXISTS v_attendance_summary;
CREATE VIEW v_attendance_summary AS
SELECT 
    g.gymmer_id,
    g.full_name,
    COUNT(a.attendance_id) AS total_visits,
    MAX(a.date) AS last_visit,
    AVG(a.duration_minutes) AS avg_duration_minutes
FROM gymmer g
LEFT JOIN attendance a ON g.gymmer_id = a.gymmer_id
WHERE g.status = 'active'
GROUP BY g.gymmer_id, g.full_name;

-- Expiring Memberships (Next 7 days)
DROP VIEW IF EXISTS v_expiring_memberships;
CREATE VIEW v_expiring_memberships AS
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
ORDER BY g.membership_end;

-- ===================================================
-- TRIGGERS
-- ===================================================

-- Auto-update membership status based on end date
DELIMITER //
DROP TRIGGER IF EXISTS update_membership_status//
CREATE TRIGGER update_membership_status
BEFORE UPDATE ON gymmer
FOR EACH ROW
BEGIN
    IF NEW.membership_end < CURDATE() AND OLD.status = 'active' THEN
        SET NEW.status = 'expired';
    END IF;
END//

-- Create notification for payment
DROP TRIGGER IF EXISTS notify_payment_received//
CREATE TRIGGER notify_payment_received
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'completed' THEN
        INSERT INTO notifications (user_type, user_id, title, message, notification_type)
        VALUES ('gymmer', NEW.gymmer_id, 'Payment Received', 
                CONCAT('Your payment of ₹', NEW.amount, ' has been received successfully.'),
                'payment_due');
    END IF;
END//

-- Notify expiring memberships (can be called by scheduled job)
DROP PROCEDURE IF EXISTS notify_expiring_memberships//
CREATE PROCEDURE notify_expiring_memberships()
BEGIN
    INSERT INTO notifications (user_type, user_id, title, message, notification_type)
    SELECT 
        'gymmer',
        gymmer_id,
        'Membership Expiring Soon',
        CONCAT('Your membership expires on ', DATE_FORMAT(membership_end, '%d-%m-%Y'), '. Please renew to continue.'),
        'membership_expiry'
    FROM gymmer
    WHERE status = 'active'
    AND membership_end BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
    AND NOT EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.user_type = 'gymmer'
        AND n.user_id = gymmer.gymmer_id
        AND n.notification_type = 'membership_expiry'
        AND DATE(n.created_at) = CURDATE()
    );
END//

DELIMITER ;

-- ===================================================
-- SAMPLE DATA INSERTION
-- ===================================================

-- Insert Admin
INSERT IGNORE INTO admin (username, password_hash, full_name, email, phone, role) VALUES
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John Administrator', 'admin@gymfit.com', '9876543210', 'super_admin'),
('manager1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Sarah Manager', 'manager@gymfit.com', '9876543211', 'manager');

-- Insert Membership Plans
INSERT IGNORE INTO membership_plan (plan_name, duration_months, price, description, features, max_trainer_sessions) VALUES
('Basic Monthly', 1, 999.00, 'Basic gym access with equipment usage', '["Gym Access", "Locker Facility", "Shower"]', 0),
('Standard Quarterly', 3, 2499.00, 'Quarterly membership with trainer consultation', '["Gym Access", "Locker Facility", "Shower", "2 Trainer Sessions/month", "Diet Consultation"]', 6),
('Premium Half-Yearly', 6, 4499.00, 'Premium membership with personal trainer', '["Gym Access", "Locker Facility", "Shower", "8 Trainer Sessions/month", "Personalized Diet Plan", "Progress Tracking"]', 48),
('Elite Annual', 12, 7999.00, 'Elite membership with all facilities', '["Gym Access", "Locker Facility", "Shower", "Unlimited Trainer Sessions", "Personalized Diet & Workout Plan", "Progress Tracking", "Nutritionist Consultation", "Spa Access"]', 999);

-- Insert Trainers
INSERT IGNORE INTO trainer (full_name, email, phone, specialization, certification, experience_years, hourly_rate, joined_date, bio) VALUES
('Rajesh Kumar', 'rajesh.trainer@gymfit.com', '9123456780', 'Strength Training', 'ACE Certified Personal Trainer', 5, 500.00, '2021-01-15', 'Specialized in muscle building and strength conditioning'),
('Priya Sharma', 'priya.trainer@gymfit.com', '9123456781', 'Yoga & Flexibility', 'RYT-500 Yoga Alliance', 3, 400.00, '2022-03-20', 'Expert in yoga, flexibility, and mindfulness training'),
('Vikram Singh', 'vikram.trainer@gymfit.com', '9123456782', 'Weight Loss', 'NASM Certified', 7, 600.00, '2019-06-10', 'Specialized in weight loss and body transformation'),
('Anjali Reddy', 'anjali.trainer@gymfit.com', '9123456783', 'Cardio & Endurance', 'ACSM Certified', 4, 450.00, '2021-09-05', 'Expert in cardiovascular fitness and endurance training');

-- Insert Gymmers
INSERT IGNORE INTO gymmer (username, password_hash, full_name, email, phone, date_of_birth, gender, address, emergency_contact, emergency_phone, plan_id, trainer_id, join_date, membership_start, membership_end, status) VALUES
('rahul_m', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Rahul Mehta', 'rahul.m@email.com', '9876501234', '1995-05-15', 'male', '123 MG Road, Bangalore', 'Sunita Mehta', '9876501235', 3, 1, '2025-11-01', '2025-11-01', '2026-05-01', 'active'),
('sneha_p', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Sneha Patil', 'sneha.p@email.com', '9876502345', '1998-08-22', 'female', '45 Park Street, Mumbai', 'Rajesh Patil', '9876502346', 2, 2, '2025-12-01', '2025-12-01', '2026-03-01', 'active'),
('amit_s', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Amit Shah', 'amit.s@email.com', '9876503456', '1992-03-10', 'male', '78 Brigade Road, Pune', 'Neha Shah', '9876503457', 4, 3, '2025-06-15', '2025-06-15', '2026-06-15', 'active'),
('kavya_n', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Kavya Nair', 'kavya.n@email.com', '9876504567', '1996-11-30', 'female', '90 Anna Salai, Chennai', 'Ramesh Nair', '9876504568', 1, 4, '2026-01-10', '2026-01-10', '2026-02-10', 'active'),
('rohan_g', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Rohan Gupta', 'rohan.g@email.com', '9876505678', '1994-07-18', 'male', '56 Connaught Place, Delhi', 'Meera Gupta', '9876505679', 3, 1, '2025-10-20', '2025-10-20', '2026-04-20', 'active');

-- Insert Gymmer Profiles
INSERT IGNORE INTO gymmer_profile (gymmer_id, height_cm, weight_kg, blood_group, fitness_goal, target_weight_kg) VALUES
(1, 175.0, 78.5, 'O+', 'muscle_gain', 85.0),
(2, 162.0, 58.0, 'A+', 'weight_loss', 55.0),
(3, 180.0, 95.0, 'B+', 'weight_loss', 80.0),
(4, 168.0, 62.0, 'AB+', 'general_fitness', 60.0),
(5, 172.0, 72.0, 'O-', 'muscle_gain', 78.0);

-- Insert Payments
INSERT IGNORE INTO payments (gymmer_id, plan_id, amount, payment_date, payment_method, transaction_id, billing_month) VALUES
(1, 3, 4499.00, '2025-11-01', 'card', 'TXN001234567', '2025-11'),
(2, 2, 2499.00, '2025-12-01', 'upi', 'UPI987654321', '2025-12'),
(3, 4, 7999.00, '2025-06-15', 'net_banking', 'NB456789123', '2025-06'),
(4, 1, 999.00, '2026-01-10', 'cash', NULL, '2026-01'),
(5, 3, 4499.00, '2025-10-20', 'card', 'TXN887766554', '2025-10');

-- Insert Attendance (Last 7 days sample)
INSERT IGNORE INTO attendance (gymmer_id, check_in_time, check_out_time, date) VALUES
(1, '2026-01-29 06:30:00', '2026-01-29 08:00:00', '2026-01-29'),
(2, '2026-01-29 07:00:00', '2026-01-29 08:30:00', '2026-01-29'),
(3, '2026-01-29 18:00:00', '2026-01-29 19:30:00', '2026-01-29'),
(5, '2026-01-29 06:00:00', '2026-01-29 07:30:00', '2026-01-29'),
(1, '2026-01-28 06:30:00', '2026-01-28 08:15:00', '2026-01-28'),
(2, '2026-01-28 17:30:00', '2026-01-28 19:00:00', '2026-01-28'),
(4, '2026-01-28 07:00:00', '2026-01-28 08:00:00', '2026-01-28'),
(1, '2026-01-27 06:45:00', '2026-01-27 08:30:00', '2026-01-27'),
(3, '2026-01-27 18:00:00', '2026-01-27 19:45:00', '2026-01-27'),
(5, '2026-01-27 06:15:00', '2026-01-27 07:45:00', '2026-01-27');

-- Insert Equipment
INSERT IGNORE INTO equipment (equipment_name, category, quantity, purchase_date, price, condition_status, location) VALUES
('Treadmill - Commercial Grade', 'Cardio', 5, '2024-01-15', 120000.00, 'excellent', 'Cardio Zone'),
('Elliptical Trainer', 'Cardio', 3, '2024-01-15', 80000.00, 'good', 'Cardio Zone'),
('Rowing Machine', 'Cardio', 2, '2024-03-20', 60000.00, 'excellent', 'Cardio Zone'),
('Bench Press Station', 'Strength', 4, '2024-02-10', 45000.00, 'good', 'Weight Training Area'),
('Squat Rack', 'Strength', 3, '2024-02-10', 55000.00, 'excellent', 'Weight Training Area'),
('Dumbbells Set (2.5kg-50kg)', 'Free Weights', 15, '2024-01-20', 85000.00, 'good', 'Free Weight Zone'),
('Barbell with Plates', 'Free Weights', 8, '2024-02-15', 120000.00, 'excellent', 'Free Weight Zone'),
('Cable Machine', 'Strength', 2, '2024-03-01', 95000.00, 'excellent', 'Weight Training Area'),
('Leg Press Machine', 'Strength', 2, '2024-02-25', 75000.00, 'good', 'Weight Training Area'),
('Yoga Mats', 'Functional', 20, '2024-04-10', 20000.00, 'good', 'Yoga Studio'),
('Kettlebells Set', 'Free Weights', 12, '2024-03-15', 35000.00, 'excellent', 'Functional Training'),
('Battle Ropes', 'Functional', 4, '2024-04-05', 12000.00, 'excellent', 'Functional Training');

-- Insert Workout Plans
INSERT IGNORE INTO workout_plan (gymmer_id, trainer_id, plan_name, day_of_week, exercises, duration_minutes, difficulty, start_date) VALUES
(1, 1, 'Muscle Building - Push', 'monday', 
 '[{"exercise":"Bench Press","sets":4,"reps":"8-10","rest":"90s"},{"exercise":"Incline Dumbbell Press","sets":3,"reps":"10-12","rest":"60s"},{"exercise":"Shoulder Press","sets":4,"reps":"8-10","rest":"90s"},{"exercise":"Tricep Dips","sets":3,"reps":"12-15","rest":"60s"}]',
 75, 'intermediate', '2025-11-01'),
(1, 1, 'Muscle Building - Pull', 'wednesday',
 '[{"exercise":"Deadlift","sets":4,"reps":"6-8","rest":"120s"},{"exercise":"Pull-ups","sets":4,"reps":"8-10","rest":"90s"},{"exercise":"Barbell Row","sets":3,"reps":"10-12","rest":"60s"},{"exercise":"Bicep Curls","sets":3,"reps":"12-15","rest":"60s"}]',
 75, 'intermediate', '2025-11-01'),
(2, 2, 'Yoga Flow', 'tuesday',
 '[{"exercise":"Sun Salutation","sets":3,"reps":"10 cycles","rest":"30s"},{"exercise":"Warrior Poses","sets":2,"reps":"Hold 30s each","rest":"15s"},{"exercise":"Tree Pose","sets":2,"reps":"Hold 45s each side","rest":"15s"},{"exercise":"Savasana","sets":1,"reps":"5 mins","rest":"0s"}]',
 60, 'beginner', '2025-12-01');

-- Insert Diet Plans
INSERT IGNORE INTO diet_plan (gymmer_id, trainer_id, plan_name, meal_type, meal_items, total_calories, total_protein_g, total_carbs_g, total_fat_g, start_date) VALUES
(1, 1, 'Muscle Gain Diet', 'breakfast',
 '[{"item":"Oats with Milk","quantity":"100g","calories":380,"protein":15},{"item":"Banana","quantity":"1 medium","calories":105,"protein":1.3},{"item":"Almonds","quantity":"10 pieces","calories":70,"protein":2.5},{"item":"Whey Protein Shake","quantity":"30g","calories":120,"protein":24}]',
 675, 42.8, 85.0, 15.0, '2025-11-01'),
(1, 1, 'Muscle Gain Diet', 'lunch',
 '[{"item":"Brown Rice","quantity":"200g","calories":220,"protein":5},{"item":"Grilled Chicken","quantity":"150g","calories":248,"protein":47},{"item":"Mixed Vegetables","quantity":"100g","calories":50,"protein":2},{"item":"Dal","quantity":"1 bowl","calories":120,"protein":8}]',
 638, 62.0, 50.0, 10.0, '2025-11-01'),
(2, 2, 'Weight Loss Diet', 'breakfast',
 '[{"item":"Egg White Omelette","quantity":"3 eggs","calories":51,"protein":11},{"item":"Whole Wheat Toast","quantity":"2 slices","calories":160,"protein":8},{"item":"Green Tea","quantity":"1 cup","calories":2,"protein":0},{"item":"Apple","quantity":"1 medium","calories":95,"protein":0.5}]',
 308, 19.5, 45.0, 3.0, '2025-12-01');

-- Insert Progress Tracking
INSERT IGNORE INTO progress_tracking (gymmer_id, record_date, weight_kg, body_fat_percentage, chest_cm, waist_cm, biceps_cm) VALUES
(1, '2025-11-01', 78.5, 18.5, 98.0, 82.0, 35.0),
(1, '2025-12-01', 79.8, 17.8, 99.5, 81.0, 35.8),
(1, '2026-01-01', 81.2, 17.2, 101.0, 80.5, 36.5),
(2, '2025-12-01', 58.0, 28.5, 86.0, 72.0, 26.0),
(2, '2026-01-01', 56.8, 26.8, 85.0, 70.0, 26.0),
(3, '2025-06-15', 95.0, 32.0, 108.0, 98.0, 38.0),
(3, '2025-09-15', 88.5, 28.5, 104.0, 92.0, 37.0);

-- ===================================================
-- USEFUL QUERIES FOR ADMIN DASHBOARD
-- ===================================================

-- Total active members
-- SELECT COUNT(*) AS total_active_members FROM gymmer WHERE status = 'active';

-- Total revenue this month
-- SELECT SUM(amount) AS monthly_revenue FROM payments 
-- WHERE DATE_FORMAT(payment_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m') AND payment_status = 'completed';

-- Today's attendance
-- SELECT COUNT(*) AS today_attendance FROM attendance WHERE date = CURDATE();

-- Members expiring in next 7 days
-- SELECT * FROM v_expiring_memberships;

-- Equipment requiring maintenance
-- SELECT * FROM equipment WHERE condition_status = 'maintenance_required' OR next_maintenance_date <= CURDATE();

-- ===================================================
-- END OF SCHEMA
-- ===================================================

