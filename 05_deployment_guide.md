# Oracle APEX Jira Ticket Tracking System
## Complete Deployment Guide for Oracle Cloud Infrastructure (OCI) with ADBS

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [OCI Setup](#oci-setup)
3. [Database Setup](#database-setup)
4. [APEX Application Creation](#apex-application-creation)
5. [Configuration](#configuration)
6. [Testing](#testing)
7. [Maintenance](#maintenance)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Access
- Oracle Cloud Infrastructure (OCI) account with appropriate permissions
- Autonomous Database (ADBS) provisioned or ability to create one
- APEX workspace credentials (or ability to create)
- SQL Developer, SQL*Plus, or OCI Cloud Shell access

### Skills Required
- Basic SQL knowledge
- Understanding of Oracle APEX concepts
- Familiarity with OCI console

---

## OCI Setup

### Step 1: Create Autonomous Database (if not exists)

1. Log in to OCI Console
2. Navigate to **Database** → **Autonomous Database**
3. Click **Create Autonomous Database**
4. Configure:
   - **Compartment**: Select your compartment
   - **Display Name**: `JiraTicketTrackerDB`
   - **Database Name**: `JIRATRACKER`
   - **Workload Type**: Transaction Processing (ATP) or Data Warehouse (ADW)
   - **Deployment Type**: Shared Infrastructure
   - **Database Version**: 19c or 21c
   - **OCPU Count**: 1 (minimum for dev/test)
   - **Storage**: 1 TB (minimum)
   - **Auto Scaling**: Enable (optional)
5. Set **Administrator Credentials**:
   - **Username**: ADMIN
   - **Password**: [Create strong password]
6. Choose **License Type**: License Included or BYOL
7. Click **Create Autonomous Database**
8. Wait for provisioning (typically 2-3 minutes)

### Step 2: Enable APEX

1. Once database is available, click on the database name
2. Under **Tools**, click **Oracle APEX**
3. Click **Open APEX**
4. Note the APEX URL (save this for later)

### Step 3: Set Up Network Access

1. In the database details page, click **DB Connection**
2. Download the **Wallet** (if needed for external connections)
3. Configure **Access Control List** if needed:
   - Allow access from your IP range
   - For development, you can allow all IPs (not recommended for production)

---

## Database Setup

### Step 1: Connect to Database

**Option A: Using SQL Developer Web** (Recommended for ADBS)
1. Go to ADBS Details page
2. Click **Database Actions** → **SQL**
3. Login with ADMIN credentials

**Option B: Using SQL Developer Desktop**
1. Download and configure wallet
2. Create new connection with wallet
3. Connect as ADMIN

### Step 2: Create Application Schema (Optional but Recommended)

```sql
-- Create dedicated schema for the application
CREATE USER jira_app_user IDENTIFIED BY "YourStrongPassword123!";

-- Grant necessary privileges
GRANT CONNECT, RESOURCE TO jira_app_user;
GRANT CREATE VIEW TO jira_app_user;
GRANT CREATE PROCEDURE TO jira_app_user;
GRANT CREATE SEQUENCE TO jira_app_user;
GRANT CREATE TABLE TO jira_app_user;
GRANT CREATE TRIGGER TO jira_app_user;
GRANT UNLIMITED TABLESPACE TO jira_app_user;

-- Additional APEX privileges
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => 'JIRA_APP_USER',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'jira',
        p_auto_rest_auth      => FALSE
    );
END;
/
```

### Step 3: Run Database Scripts

Connect as the application schema (or ADMIN if using single schema):

**Execute scripts in order:**

1. **Schema Creation**
   ```bash
   @01_database_schema.sql
   ```

2. **PL/SQL Packages**
   ```bash
   @02_plsql_packages.sql
   ```

3. **APEX Setup**
   ```bash
   @03_apex_setup.sql
   ```

### Step 4: Verify Installation

```sql
-- Check tables
SELECT table_name FROM user_tables ORDER BY table_name;

-- Should see:
-- JIRA_TICKET_HISTORY
-- JIRA_TICKETS
-- TEAM_MEMBERS
-- TEAMS

-- Check packages
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_type = 'PACKAGE'
ORDER BY object_name;

-- Should see:
-- JIRA_TICKET_PKG (VALID)

-- Check sample data
SELECT COUNT(*) FROM teams;
SELECT COUNT(*) FROM team_members;
SELECT COUNT(*) FROM jira_tickets;

-- Should have sample records in each table
```

---

## APEX Application Creation

### Step 1: Access APEX Workspace

1. Navigate to APEX URL from OCI console
2. Login to APEX Administration
3. Create New Workspace (if needed):
   - **Workspace Name**: `JIRA_TRACKER_WS`
   - **Workspace ID**: Auto-generated
   - **Workspace Administrator**: Your admin user
   - **Email**: Your email
   - **Password**: Set password

### Step 2: Create Application

1. Sign in to the workspace
2. Click **App Builder**
3. Click **Create** → **New Application**
4. Choose **From Scratch**
5. Configure:
   - **Name**: `Jira Ticket Tracker`
   - **Application ID**: Auto-generated
   - **Appearance**: Universal Theme - 42 (Recommended)
   - **Navigation**: Side Navigation

### Step 3: Configure Application Settings

1. Go to **Shared Components**
2. Configure **Application Definition**:
   - **Application Name**: Jira Ticket Tracker
   - **Application Alias**: JIRA_TRACKER
   - **Version**: 1.0
   - **Logging**: Yes
   - **Debugging**: Yes

### Step 4: Set Up Authentication

1. **Shared Components** → **Authentication Schemes**
2. For development, use **Application Express Accounts**
3. For production, configure:
   - **LDAP Directory** if using corporate directory
   - **Oracle SSO** if using Oracle identity
   - **Custom** for other authentication methods

### Step 5: Create Application Items

1. **Shared Components** → **Application Items**
2. Create the following items:
   - `APP_USER_NAME` (Session State Protection: Unrestricted)
   - `APP_USER_TEAM_ID` (Session State Protection: Unrestricted)
   - `APP_USER_ROLE` (Session State Protection: Unrestricted)

### Step 6: Create Authorization Schemes

1. **Shared Components** → **Authorization Schemes**
2. Create four schemes as documented in `03_apex_setup.sql`:
   - **Can View**: Basic read access
   - **Can Edit**: Edit permissions
   - **Can Manage**: Management permissions
   - **Is Admin**: Full admin access

### Step 7: Create Application Process

1. **Shared Components** → **Application Processes**
2. Create **Set User Context**:
   - **Process Point**: On New Session: Before Header
   - **PL/SQL Code**: From `03_apex_setup.sql`

### Step 8: Create List of Values

1. **Shared Components** → **List of Values**
2. Create all LOVs from `03_apex_setup.sql`:
   - LOV_TEAMS
   - LOV_STATUS
   - LOV_TICKET_TYPE
   - LOV_PRIORITY
   - LOV_MEMBER_ROLE
   - LOV_ASSIGNEES

### Step 9: Create Pages

Follow the detailed instructions in `04_apex_pages_guide.md` to create:
- Page 0: Global Page (Navigation)
- Page 1: Home Dashboard
- Page 2: Ticket List
- Page 3: Ticket Details
- Page 4: Weekly Status Report
- Page 5: Team Management
- Page 6: User Administration
- Page 7: Analytics & Charts

---

## Configuration

### User Setup

1. **Create APEX Users** (if using Application Express Accounts):
   ```sql
   -- In SQL Workshop or as ADMIN
   BEGIN
       apex_util.create_user(
           p_user_name     => 'DEVELOPER1',
           p_email_address => 'developer1@company.com',
           p_web_password  => 'TempPassword123!',
           p_change_password_on_first_use => 'Y'
       );
   END;
   /
   ```

2. **Add Users to Teams**:
   ```sql
   INSERT INTO team_members (team_id, username, email, member_role)
   VALUES (1, 'DEVELOPER1', 'developer1@company.com', 'EDITOR');
   COMMIT;
   ```

### Customization

1. **Logo and Branding**:
   - **Shared Components** → **User Interface Attributes**
   - Upload company logo
   - Set application icon
   - Customize colors if needed

2. **Email Settings** (for notifications):
   ```sql
   -- Configure email settings
   BEGIN
       apex_instance_admin.set_parameter(
           p_parameter => 'SMTP_HOST_ADDRESS',
           p_value     => 'smtp.yourcompany.com'
       );
   END;
   /
   ```

3. **Regional Settings**:
   - **Application Definition** → **Globalization**
   - Set default date format: `MM/DD/YYYY`
   - Set default timestamp format: `MM/DD/YYYY HH24:MI`

---

## Testing

### Functional Testing

1. **Test as Different Users**:
   - Admin user - Full access
   - Manager user - Team management access
   - Editor user - Edit access
   - Viewer user - Read-only access

2. **Test CRUD Operations**:
   ```sql
   -- Verify ticket creation
   INSERT INTO jira_tickets (team_id, jira_key, ticket_summary, ticket_type, priority, status)
   VALUES (1, 'TEST-001', 'Test Ticket', 'Task', 'Medium', 'To Do');
   
   -- Verify ticket update
   UPDATE jira_tickets 
   SET status = 'In Progress'
   WHERE jira_key = 'TEST-001';
   
   -- Verify snapshot creation
   BEGIN
       jira_ticket_pkg.create_all_weekly_snapshots;
   END;
   /
   
   -- Check results
   SELECT * FROM jira_ticket_history WHERE jira_key = 'TEST-001';
   ```

3. **Test Reports and Charts**:
   - Navigate to each page
   - Verify data displays correctly
   - Test filters and search
   - Verify charts render properly

### Performance Testing

```sql
-- Check query performance
SET TIMING ON
SET AUTOTRACE ON

-- Test main dashboard query
SELECT * FROM v_jira_tickets_dashboard WHERE team_id = 1;

-- Test weekly report query
SELECT * FROM v_weekly_status_report 
WHERE week_year = 2026 AND team_name = 'Development Team';

SET AUTOTRACE OFF
SET TIMING OFF
```

### Security Testing

1. Test authorization schemes:
   - Try accessing restricted pages as viewer
   - Verify edit buttons are hidden for viewers
   - Confirm managers can access team management

2. Test data isolation:
   - Ensure users only see their team's data
   - Verify cross-team data is not accessible

---

## Maintenance

### Daily Tasks

1. Monitor application logs:
   ```sql
   SELECT * FROM apex_activity_log
   WHERE application_id = [your_app_id]
     AND time_stamp > SYSDATE - 1
   ORDER BY time_stamp DESC;
   ```

2. Check for errors:
   ```sql
   SELECT * FROM apex_debug_messages
   WHERE application_id = [your_app_id]
     AND message LIKE '%ERROR%'
     AND time_stamp > SYSDATE - 1;
   ```

### Weekly Tasks

1. **Review Weekly Snapshots**:
   ```sql
   SELECT week_year, week_number, COUNT(*) as snapshot_count
   FROM jira_ticket_history
   GROUP BY week_year, week_number
   ORDER BY week_year DESC, week_number DESC;
   ```

2. **Check Scheduler Job**:
   ```sql
   SELECT job_name, state, last_start_date, next_run_date, failure_count
   FROM user_scheduler_jobs
   WHERE job_name = 'WEEKLY_TICKET_SNAPSHOT_JOB';
   ```

### Monthly Tasks

1. **Archive Old Data** (if needed):
   ```sql
   -- Archive history older than 6 months
   CREATE TABLE jira_ticket_history_archive AS
   SELECT * FROM jira_ticket_history
   WHERE snapshot_date < ADD_MONTHS(SYSDATE, -6);
   
   DELETE FROM jira_ticket_history
   WHERE snapshot_date < ADD_MONTHS(SYSDATE, -6);
   
   COMMIT;
   ```

2. **Review User Access**:
   ```sql
   SELECT username, member_role, COUNT(*) as team_count
   FROM team_members
   WHERE is_active = 'Y'
   GROUP BY username, member_role;
   ```

3. **Backup Application**:
   - Export APEX application
   - Export database objects
   - Document any custom configurations

### Performance Tuning

1. **Gather Statistics**:
   ```sql
   BEGIN
       DBMS_STATS.GATHER_SCHEMA_STATS(
           ownname => USER,
           cascade => TRUE
       );
   END;
   /
   ```

2. **Check Index Usage**:
   ```sql
   SELECT index_name, table_name, num_rows
   FROM user_indexes
   WHERE table_name IN ('JIRA_TICKETS', 'JIRA_TICKET_HISTORY', 'TEAMS', 'TEAM_MEMBERS');
   ```

---

## Troubleshooting

### Common Issues

#### Issue: Users Cannot Login
**Solution**:
```sql
-- Check if user exists
SELECT username, account_status 
FROM apex_workspace_apex_users
WHERE workspace_name = 'JIRA_TRACKER_WS';

-- Reset password if needed
BEGIN
    apex_util.edit_user(
        p_user_name => 'USERNAME',
        p_web_password => 'NewPassword123!'
    );
END;
/
```

#### Issue: Data Not Visible
**Solution**:
```sql
-- Check team membership
SELECT * FROM team_members WHERE username = 'USERNAME';

-- Check application items
-- Run this in Application Debug mode to see session state
```

#### Issue: Weekly Snapshots Not Creating
**Solution**:
```sql
-- Check job status
SELECT * FROM user_scheduler_job_run_details
WHERE job_name = 'WEEKLY_TICKET_SNAPSHOT_JOB'
ORDER BY log_date DESC;

-- Manually run job
BEGIN
    DBMS_SCHEDULER.RUN_JOB('WEEKLY_TICKET_SNAPSHOT_JOB');
END;
/

-- Check for errors
SELECT * FROM user_scheduler_job_log
WHERE job_name = 'WEEKLY_TICKET_SNAPSHOT_JOB';
```

#### Issue: Performance Degradation
**Solution**:
```sql
-- Check table sizes
SELECT table_name, num_rows, blocks
FROM user_tables
WHERE table_name IN ('JIRA_TICKETS', 'JIRA_TICKET_HISTORY');

-- Rebuild indexes if needed
ALTER INDEX idx_tickets_week REBUILD;
ALTER INDEX idx_history_week REBUILD;

-- Update statistics
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'JIRA_TICKETS');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'JIRA_TICKET_HISTORY');
END;
/
```

### Debug Mode

Enable debug mode in APEX:
1. Click **Debug** on any page
2. Review debug output for errors
3. Check session state values
4. Analyze SQL queries

### Logging

Enable detailed logging:
```sql
-- Enable APEX debug for specific application
BEGIN
    apex_debug.enable(p_level => apex_debug.c_log_level_info);
END;
/
```

---

## Best Practices

### Security
1. Use strong passwords
2. Enable session timeout
3. Implement session state protection
4. Regular security audits
5. Keep APEX updated

### Performance
1. Use pagination for large datasets
2. Implement caching where appropriate
3. Optimize SQL queries
4. Regular index maintenance
5. Archive old data

### Usability
1. Provide clear error messages
2. Include helpful tooltips
3. Implement responsive design
4. Test across different browsers
5. Gather user feedback

### Documentation
1. Document all customizations
2. Maintain change log
3. Keep deployment guide updated
4. Document API integrations
5. Train end users

---

## Support and Resources

### Oracle Resources
- APEX Documentation: https://apex.oracle.com/doc
- OCI Documentation: https://docs.oracle.com/cloud
- Community Forums: https://community.oracle.com/apex

### Additional Help
- Oracle Support (if you have support contract)
- APEX Community Slack
- Stack Overflow (tag: oracle-apex)

---

## Appendix

### A. Sample Data Generation

```sql
-- Generate sample tickets for testing
BEGIN
    FOR i IN 1..50 LOOP
        INSERT INTO jira_tickets (
            team_id, jira_key, ticket_summary, ticket_type, 
            priority, status, assignee, story_points
        ) VALUES (
            1,
            'TEST-' || LPAD(i, 4, '0'),
            'Sample Ticket ' || i,
            CASE MOD(i, 4) 
                WHEN 0 THEN 'Story'
                WHEN 1 THEN 'Bug'
                WHEN 2 THEN 'Task'
                ELSE 'Improvement'
            END,
            CASE MOD(i, 3)
                WHEN 0 THEN 'High'
                WHEN 1 THEN 'Medium'
                ELSE 'Low'
            END,
            CASE MOD(i, 4)
                WHEN 0 THEN 'To Do'
                WHEN 1 THEN 'In Progress'
                WHEN 2 THEN 'Done'
                ELSE 'Blocked'
            END,
            'DEVELOPER' || MOD(i, 3) + 1,
            ROUND(DBMS_RANDOM.VALUE(1, 13))
        );
    END LOOP;
    COMMIT;
END;
/
```

### B. Useful SQL Queries

```sql
-- Team Statistics
SELECT 
    t.team_name,
    COUNT(jt.ticket_id) as total_tickets,
    SUM(CASE WHEN jt.status = 'Done' THEN 1 ELSE 0 END) as completed,
    SUM(jt.story_points) as total_points
FROM teams t
LEFT JOIN jira_tickets jt ON t.team_id = jt.team_id
WHERE jt.is_active = 'Y'
GROUP BY t.team_name;

-- User Activity
SELECT 
    updated_by as user,
    COUNT(*) as updates,
    MAX(updated_date) as last_activity
FROM jira_tickets
WHERE updated_date > SYSDATE - 7
GROUP BY updated_by
ORDER BY updates DESC;

-- Weekly Trends
SELECT 
    week_year,
    week_number,
    status,
    COUNT(*) as count
FROM jira_ticket_history
WHERE week_year = 2026
GROUP BY week_year, week_number, status
ORDER BY week_number, status;
```

---

## Version History

- **v1.0** (February 2026) - Initial deployment guide
- Document includes complete setup for OCI ADBS deployment
- Role-based security implementation
- Weekly snapshot functionality

---

**End of Deployment Guide**
