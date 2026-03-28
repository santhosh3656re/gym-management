# 🏋️ GYM MANAGEMENT SYSTEM

A comprehensive, database-driven web application for modern gym operations with separate Admin and Member dashboards.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue.svg)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Technology Stack](#technology-stack)
- [Database Schema](#database-schema)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

The Gym Management System is a full-featured web application designed to streamline gym operations through automation and data-driven insights. It provides two specialized interfaces:

- **Admin Dashboard** - Complete control panel for gym management
- **Gymmer Dashboard** - Member-focused self-service portal

### Key Highlights

✅ **15 Database Tables** with proper normalization (1NF, 2NF, 3NF)  
✅ **Comprehensive Features** covering all gym operations  
✅ **Modern UI/UX** with dark gym theme and smooth animations  
✅ **Real-time Analytics** with visual dashboards  
✅ **Mobile Responsive** design for all devices  
✅ **Production Ready** code with industry standards  

---

## 🚀 Features

### Admin Module

#### 👥 Member Management
- Add, edit, delete, and view members
- Search and filter by status, plan, or trainer
- Track membership expiry dates
- Monitor member health stats and progress
- Bulk operations (import/export)

#### 💪 Trainer Management
- Manage trainer profiles and credentials
- Track specializations and certifications
- Assign trainers to members
- Monitor trainer utilization
- Session scheduling

#### 📋 Membership Plans
- Create and manage multiple plan types
- Flexible pricing and duration
- Feature customization per plan
- Plan analytics and popularity tracking

#### 💳 Payment & Billing
- Record payments with multiple methods
- Generate receipts and invoices
- Track payment history
- Monitor outstanding dues
- Revenue reporting and analytics

#### 📅 Attendance Tracking
- Real-time attendance monitoring
- Manual check-in/check-out
- Attendance reports and analytics
- Identify irregular members
- Peak hours analysis

#### 🏋️ Equipment Management
- Complete equipment inventory
- Maintenance scheduling
- Condition monitoring
- Purchase tracking
- Depreciation calculation

#### 📊 Reports & Analytics
- Pre-built report templates
- Custom date range selection
- Visual charts and graphs
- Export to PDF/Excel
- Email delivery

### Gymmer Module

#### 🏠 Personal Dashboard
- Welcome screen with quick stats
- Workout count and hours trained
- Progress metrics display
- Motivational elements

#### 📊 Health Stats
- Current weight and BMI tracking
- Body measurements (chest, waist, biceps)
- Visual BMI indicator
- Progress over time

#### 💳 Membership Info
- Current plan details and features
- Membership dates and expiry
- Days remaining countdown
- Renewal options
- Payment history

#### 👨‍🏫 Trainer Profile
- Assigned trainer information
- Specialization and certifications
- Contact details
- Session booking
- Trainer ratings

#### 🏋️ Workout Plans
- Weekly workout schedule
- Day-wise exercise breakdown
- Sets, reps, and rest times
- Workout duration
- Difficulty level

#### 🥗 Diet Plans
- Daily meal schedule
- Meal-wise food items
- Nutritional information
- Calorie and macro tracking
- Alternative food options

#### 📅 Attendance Tracker
- One-click check-in system
- Visual monthly calendar
- Attendance statistics
- Attendance percentage
- Consistency tracking

#### 💰 Payment History
- Complete transaction history
- Receipt downloads
- Payment method tracking
- Next payment due alerts

---

## 📸 Screenshots

### Admin Dashboard
Modern dark-themed interface with real-time statistics and analytics.

### Gymmer Dashboard
User-friendly member portal with personalized fitness tracking.

---

## 💻 Technology Stack

### Frontend
- **HTML5** - Semantic markup and structure
- **CSS3** - Modern styling with animations
  - CSS Grid & Flexbox for layouts
  - CSS Variables for theming
  - Keyframe animations
- **JavaScript (ES6+)** - Interactive functionality
  - DOM manipulation
  - Event handling
  - Local storage

### Database
- **MySQL 8.0+** - Relational database
  - 15 normalized tables
  - Foreign key relationships
  - Triggers and stored procedures
  - Views for complex queries
  - Indexes for optimization

### Design
- **Google Fonts** - Orbitron, Rajdhani
- **Custom Icons** - Emoji-based icon system
- **Color Scheme** - Dark gym theme
  - Primary: #FF0844 (Red)
  - Accent: #FFB800 (Yellow)
  - Background: #0A0A0A (Black)

### Recommended Backend (for production)
- **PHP 7.4+** or **Node.js 14+**
- **Apache** or **Nginx** web server
- **RESTful API** architecture
- **JWT** for authentication

---

## 🗄️ Database Schema

### Core Tables

#### Admin Module Tables
1. **admin** - System administrators
2. **membership_plan** - Membership plan definitions
3. **trainer** - Trainer profiles
4. **gymmer** - Member master data
5. **payments** - Payment transactions
6. **attendance** - Daily attendance records
7. **equipment** - Equipment inventory

#### Gymmer Module Tables
8. **gymmer_profile** - Member health data
9. **workout_plan** - Personalized workouts
10. **diet_plan** - Customized diets
11. **progress_tracking** - Body measurements
12. **training_sessions** - Trainer sessions
13. **notifications** - System notifications

### Key Relationships

```
MEMBERSHIP_PLAN (1) ──→ (M) GYMMER
TRAINER (1) ──→ (M) GYMMER
GYMMER (1) ──→ (M) PAYMENTS
GYMMER (1) ──→ (M) ATTENDANCE
GYMMER (1) ──→ (1) GYMMER_PROFILE
GYMMER (1) ──→ (M) WORKOUT_PLAN
GYMMER (1) ──→ (M) DIET_PLAN
```

### Database Features

✅ Primary and Foreign Keys  
✅ Unique Constraints  
✅ Check Constraints with Enums  
✅ Computed Columns (BMI)  
✅ Indexes for Performance  
✅ Views for Reporting  
✅ Triggers for Automation  
✅ Stored Procedures  

---

## 📦 Installation

### Prerequisites

- Web server (Apache/Nginx)
- MySQL 8.0 or higher
- PHP 7.4+ or Node.js 14+ (for backend)
- Modern web browser

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/gym-management-system.git
cd gym-management-system
```

### Step 2: Database Setup

```bash
# Login to MySQL
mysql -u root -p

# Create database and import schema
mysql -u root -p < database/schema.sql
```

### Step 3: Configure Application

Create a `config.php` file:

```php
<?php
define('DB_HOST', 'localhost');
define('DB_USER', 'your_username');
define('DB_PASS', 'your_password');
define('DB_NAME', 'gym_management');
?>
```

### Step 4: Deploy Files

Copy files to your web server directory:

```bash
cp -r * /var/www/html/gym-management/
```

### Step 5: Set Permissions

```bash
chmod 755 /var/www/html/gym-management
chmod 644 /var/www/html/gym-management/config.php
```

### Step 6: Access Application

- **Admin Panel**: `http://localhost/gym-management/admin/admin-dashboard.html`
- **Member Portal**: `http://localhost/gym-management/gymmer/gymmer-dashboard.html`

### Default Login Credentials

**Admin:**
- Username: `admin`
- Password: `admin123`

**Sample Gymmer:**
- Username: `rahul_m`
- Password: `password123`

⚠️ **Important:** Change default passwords immediately after first login!

---

## 📖 Usage

### Admin Workflow

1. **Login** to Admin Dashboard
2. **Manage Members** - Add/edit/view gym members
3. **Assign Trainers** - Allocate trainers to members
4. **Track Payments** - Record and monitor payments
5. **Monitor Attendance** - View daily check-ins
6. **Generate Reports** - Create analytics reports
7. **Manage Equipment** - Track inventory and maintenance

### Gymmer Workflow

1. **Login** to Gymmer Dashboard
2. **View Dashboard** - Check stats and progress
3. **Check Workout Plan** - Review daily exercises
4. **Check Diet Plan** - View meal schedule
5. **Check-In** - Mark daily attendance
6. **Track Progress** - Monitor health metrics
7. **View Payments** - Check payment history

---

## 📁 Project Structure

```
gym-management-system/
│
├── admin/
│   └── admin-dashboard.html       # Admin interface
│
├── gymmer/
│   └── gymmer-dashboard.html      # Member interface
│
├── database/
│   └── schema.sql                 # Database schema & sample data
│
├── documentation/
│   └── PROJECT_DOCUMENTATION.md   # Comprehensive documentation
│
├── assets/
│   ├── css/                       # Stylesheets (if separated)
│   ├── js/                        # JavaScript files (if separated)
│   └── images/                    # Image assets
│
├── README.md                      # This file
└── LICENSE                        # License information
```

---

## 🎨 Design Philosophy

### Color Palette

- **Primary Red**: `#FF0844` - Action buttons, highlights
- **Secondary Red**: `#C70039` - Gradients, accents
- **Accent Yellow**: `#FFB800` - Success states, highlights
- **Accent Cyan**: `#00F0FF` - Information, links
- **Success Green**: `#00FF88` - Positive indicators
- **Dark Background**: `#0A0A0A` - Main background
- **Card Background**: `#161616` - Content cards
- **Border Color**: `#2A2A2A` - Subtle borders

### Typography

- **Display Font**: Orbitron (900 weight) - Headlines, numbers
- **Body Font**: Rajdhani (400-700 weights) - Content
- **Letter Spacing**: Generous for headers (2px+)
- **Line Height**: 1.6 for readability

### UI Components

- **Cards**: Elevated with borders and hover effects
- **Buttons**: Gradient backgrounds with hover animations
- **Tables**: Row hover effects and zebra striping
- **Forms**: Clean inputs with focus states
- **Modals**: Centered with backdrop blur

---

## 🔧 Customization

### Changing Color Scheme

Edit CSS variables in the HTML files:

```css
:root {
    --primary-red: #FF0844;
    --accent-yellow: #FFB800;
    /* Customize other colors */
}
```

### Adding New Features

1. Create database tables in `schema.sql`
2. Add UI components to dashboard HTML
3. Implement business logic in backend
4. Test thoroughly before deployment

### Branding

- Replace logo text in HTML
- Update gym name and contact info
- Customize email templates
- Modify color scheme

---

## 📊 Database ER Diagram

See `documentation/PROJECT_DOCUMENTATION.md` for detailed ER diagram and relationship explanations.

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Development Guidelines

- Follow existing code style
- Comment your code appropriately
- Test all changes thoroughly
- Update documentation as needed
- Keep commits atomic and descriptive

---

## 🐛 Bug Reports

Found a bug? Please create an issue with:

- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable
- Environment details (OS, browser, etc.)

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

- **Database Project Team** - Initial work

---

## 🙏 Acknowledgments

- Google Fonts for typography
- MySQL for robust database
- Inspiration from modern gym management needs
- All contributors and testers

---

## 📞 Support

For support, email admin@gymfit.com or create an issue in the repository.

---

## 🚀 Deployment

### Production Checklist

- [ ] Change all default passwords
- [ ] Enable HTTPS (SSL certificate)
- [ ] Configure email/SMS services
- [ ] Set up automated backups
- [ ] Configure firewall rules
- [ ] Test all features thoroughly
- [ ] Monitor error logs
- [ ] Set up analytics
- [ ] Create user documentation
- [ ] Train staff on system usage

### Recommended Hosting

- **Shared Hosting**: Suitable for small gyms (<100 members)
- **VPS**: Recommended for medium gyms (100-500 members)
- **Cloud**: Best for large gyms or multi-location (500+ members)

---

## 📈 Roadmap

### Version 2.0 (Planned)

- [ ] Mobile application (iOS & Android)
- [ ] Payment gateway integration
- [ ] Advanced analytics with ML
- [ ] Video workout library
- [ ] Wearable device integration
- [ ] Multi-language support
- [ ] Dark/Light theme toggle
- [ ] Advanced reporting dashboard

---

## 🎓 Educational Value

This project demonstrates:

- **Database Design**: Normalization, relationships, constraints
- **Frontend Development**: HTML5, CSS3, JavaScript
- **UI/UX Design**: Modern interface, responsive layout
- **System Architecture**: Multi-module design
- **Documentation**: Comprehensive technical documentation
- **Best Practices**: Clean code, security, performance

Perfect for:
- College database projects
- Portfolio showcase
- Learning full-stack development
- Understanding gym operations
- Practical database application

---

## ⭐ Star History

If you find this project helpful, please consider giving it a star!

---

**Made with ❤️ for the fitness community**

Last Updated: January 29, 2026
