# Oracle APEX Jira Ticket Tracking System

A comprehensive role-based ticket tracking application built on Oracle APEX with Autonomous Database (ADBS) backend on Oracle Cloud Infrastructure.

## 📋 Overview

This application provides a complete solution for tracking Jira tickets with weekly status snapshots, team management, and role-based access control. It's designed to help teams monitor their work items, track progress over time, and generate insightful reports.

## ✨ Key Features

### Core Functionality
- **Ticket Management**: Create, view, update, and track Jira tickets
- **Weekly Snapshots**: Automatic weekly status captures for historical tracking
- **Team-Based Organization**: Organize tickets and users by teams
- **Rich Data Model**: Track story points, time estimates, sprints, and more
- **Interactive Dashboards**: Visual analytics and KPI monitoring
- **Historical Reporting**: View trends and changes over time

### Role-Based Access Control
Four distinct user roles with appropriate permissions:
- **VIEWER**: Read-only access to tickets and reports
- **EDITOR**: Can create and modify tickets
- **MANAGER**: Can manage tickets and view team members
- **ADMIN**: Full system access including user administration

### Advanced Features
- Automatic week calculation and assignment
- Weekly snapshot automation via scheduled jobs
- Comprehensive audit trail
- Multi-team support
- Interactive grids for easy data editing
- Responsive design for mobile and desktop
- Export capabilities for reports

## 🏗️ Architecture

### Technology Stack
- **Database**: Oracle Autonomous Database (ADBS) on OCI
- **Application**: Oracle APEX 23.x or higher
- **Language**: PL/SQL, SQL
- **UI Framework**: Universal Theme 42

### Database Schema
```
teams
├── team_members (role-based membership)
└── jira_tickets
    └── jira_ticket_history (weekly snapshots)
```

### Security Model
- Row-level security based on team membership
- Function-based authorization schemes
- Session state protection
- Audit columns on all tables

## 📦 Package Contents

| File | Description |
|------|-------------|
| `01_database_schema.sql` | Complete database schema with tables, indexes, sample data |
| `02_plsql_packages.sql` | Business logic package and triggers |
| `03_apex_setup.sql` | APEX configuration SQL (LOVs, processes, etc.) |
| `04_apex_pages_guide.md` | Detailed page-by-page configuration guide |
| `05_deployment_guide.md` | Complete deployment and maintenance guide |
| `README.md` | This file - project overview and quick start |

## 🚀 Quick Start

### Prerequisites
- Oracle Cloud Infrastructure (OCI) account
- Autonomous Database provisioned (ATP or ADW)
- APEX workspace access
- SQL access to the database (SQL Developer Web or Desktop)

### Installation Steps

#### 1. Database Setup (5-10 minutes)
```sql
-- Connect to your ADBS as ADMIN or schema owner
-- Run scripts in order:
@01_database_schema.sql
@02_plsql_packages.sql
@03_apex_setup.sql
```

#### 2. Verify Installation
```sql
-- Check that all objects are created
SELECT table_name FROM user_tables;
SELECT object_name, object_type FROM user_objects WHERE object_type = 'PACKAGE';

-- Verify sample data
SELECT * FROM teams;
SELECT * FROM team_members;
SELECT * FROM jira_tickets;
```

#### 3. Create APEX Application (15-20 minutes)
1. Log in to APEX workspace
2. Create new application: "Jira Ticket Tracker"
3. Set up Application Items (APP_USER_NAME, APP_USER_TEAM_ID, APP_USER_ROLE)
4. Create Authorization Schemes (Can View, Can Edit, Can Manage, Is Admin)
5. Create Application Process (Set User Context)
6. Create List of Values (teams, status, priorities, etc.)

#### 4. Build Pages (30-45 minutes)
Follow the detailed guide in `04_apex_pages_guide.md` to create:
- Page 1: Home Dashboard
- Page 2: Ticket List (Interactive Grid)
- Page 3: Ticket Details (Form)
- Page 4: Weekly Status Report
- Page 5: Team Management
- Page 6: User Administration (Admin only)
- Page 7: Analytics & Charts

#### 5. Test and Deploy
1. Create test users with different roles
2. Test CRUD operations
3. Verify authorization schemes
4. Test reports and charts
5. Enable for production use

**Total Setup Time**: ~1-2 hours

## 👥 User Roles and Permissions

| Role | View Tickets | Create/Edit | Delete | Manage Teams | User Admin |
|------|:------------:|:-----------:|:------:|:------------:|:----------:|
| **VIEWER** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **EDITOR** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **MANAGER** | ✅ | ✅ | ✅ | ✅ | ❌ |
| **ADMIN** | ✅ | ✅ | ✅ | ✅ | ✅ |

## 📊 Data Model

### Core Tables

#### TEAMS
Stores team information
- `team_id` (PK)
- `team_name` (unique)
- `team_description`
- `is_active`

#### TEAM_MEMBERS
User-team associations with roles
- `member_id` (PK)
- `team_id` (FK)
- `username`
- `member_role` (ADMIN, MANAGER, EDITOR, VIEWER)
- `is_active`

#### JIRA_TICKETS
Main ticket storage
- `ticket_id` (PK)
- `team_id` (FK)
- `jira_key` (unique)
- `ticket_summary`
- `status`, `priority`, `type`
- `assignee`, `reporter`, `sprint`
- `story_points`, time estimates
- `week_number`, `week_year` (auto-calculated)

#### JIRA_TICKET_HISTORY
Weekly snapshots of tickets
- `history_id` (PK)
- `ticket_id` (FK)
- `status`, `assignee`, `sprint`
- `week_number`, `week_year`
- `snapshot_date`

## 🔧 Configuration Options

### Weekly Snapshots
Automatic snapshots are created via scheduled job:
```sql
-- Job runs every Monday at 1 AM
-- Modify schedule if needed
BEGIN
    DBMS_SCHEDULER.SET_ATTRIBUTE(
        name => 'WEEKLY_TICKET_SNAPSHOT_JOB',
        attribute => 'repeat_interval',
        value => 'FREQ=WEEKLY; BYDAY=MON; BYHOUR=1'
    );
END;
/
```

### Authentication
Default: APEX Application Express Accounts
Optional: LDAP, SSO, Custom authentication

### Email Notifications
Configure SMTP for email alerts:
```sql
BEGIN
    apex_instance_admin.set_parameter(
        p_parameter => 'SMTP_HOST_ADDRESS',
        p_value => 'your-smtp-server.com'
    );
END;
/
```

## 📈 Sample Reports

### Key Metrics Dashboard
- Total active tickets
- Tickets in progress
- Current week activity
- Story points completed

### Weekly Status Report
- Tickets by status per week
- Historical trends
- Team velocity
- Burndown charts

### Team Performance
- Tickets completed per assignee
- Story points per team member
- Time tracking summaries

## 🔐 Security Features

### Application Level
- Session state protection on all pages
- HTTPS enforcement (via OCI ADBS)
- Password complexity requirements
- Session timeout configuration

### Database Level
- Row-level security via team_id
- Audit columns (created_by, updated_by, timestamps)
- Database triggers for automatic auditing
- Function-based authorization

### Access Control
- Team-based data isolation
- Role-based feature access
- Authorization schemes on pages, regions, buttons
- PL/SQL security package (jira_ticket_pkg)

## 🐛 Troubleshooting

### Common Issues

**Issue**: Users can't see any data
```sql
-- Check team membership
SELECT * FROM team_members WHERE username = 'USERNAME';

-- Verify application items are set
-- Use APEX Debug mode to check session state
```

**Issue**: Weekly snapshots not creating
```sql
-- Check job status
SELECT * FROM user_scheduler_jobs 
WHERE job_name = 'WEEKLY_TICKET_SNAPSHOT_JOB';

-- Run manually
BEGIN
    jira_ticket_pkg.create_all_weekly_snapshots;
END;
/
```

**Issue**: Performance slow
```sql
-- Gather statistics
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(USER);
END;
/

-- Check indexes
SELECT * FROM user_indexes 
WHERE table_name LIKE 'JIRA%';
```

## 📚 Documentation

- **Deployment Guide**: `05_deployment_guide.md` - Complete setup instructions
- **Page Configuration**: `04_apex_pages_guide.md` - Detailed APEX page setup
- **Database Schema**: `01_database_schema.sql` - Full DDL with comments
- **Business Logic**: `02_plsql_packages.sql` - PL/SQL package documentation

## 🛠️ Customization

### Add Custom Fields
```sql
-- Add new column to tickets
ALTER TABLE jira_tickets ADD custom_field VARCHAR2(100);

-- Update form page to include new field
-- Add to Interactive Grid column list
```

### Add New Status Values
```sql
-- Status is a free-form field, just use new values
-- Or create a lookup table for strict validation
CREATE TABLE ticket_statuses (
    status_code VARCHAR2(50) PRIMARY KEY,
    status_name VARCHAR2(100),
    sort_order NUMBER
);
```

### Integrate with Jira API
```sql
-- Create REST Data Source in APEX
-- Or use UTL_HTTP for custom integration
-- Example webhook endpoint for Jira updates
```

## 🤝 Contributing

This is a template application. Customize as needed for your organization:
1. Fork or copy the code
2. Modify schema to match your needs
3. Adjust roles and permissions
4. Customize UI/UX
5. Add integrations

## 📝 License

This is a sample application provided as-is for educational and development purposes.

## 🆘 Support

For issues or questions:
1. Review the deployment guide
2. Check troubleshooting section
3. Consult Oracle APEX documentation
4. Contact your Oracle support representative

## 📅 Version History

- **v1.0** (February 2026)
  - Initial release
  - Core ticket management
  - Role-based access control
  - Weekly snapshot functionality
  - Interactive dashboards
  - Team management

## 🎯 Roadmap

Potential future enhancements:
- [ ] Jira REST API integration for auto-sync
- [ ] Email notifications on ticket updates
- [ ] Custom workflows and state transitions
- [ ] Advanced analytics and forecasting
- [ ] Mobile app version
- [ ] Slack/Teams integration
- [ ] Custom fields and ticket types
- [ ] File attachments
- [ ] Comment threads
- [ ] Time tracking improvements

## 🙏 Acknowledgments

Built using:
- Oracle APEX (Application Express)
- Oracle Autonomous Database
- Oracle Cloud Infrastructure
- Universal Theme 42

---

**Ready to get started?** See `05_deployment_guide.md` for detailed installation instructions.

**Need help with pages?** Check `04_apex_pages_guide.md` for step-by-step page creation.

**Questions about the data model?** Review `01_database_schema.sql` for complete schema documentation.
