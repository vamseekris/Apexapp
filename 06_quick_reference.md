# Quick Reference Guide - Jira Ticket Tracking System
## Common Operations and SQL Examples

---

## Table of Contents
1. [User Management](#user-management)
2. [Team Management](#team-management)
3. [Ticket Operations](#ticket-operations)
4. [Reporting Queries](#reporting-queries)
5. [Maintenance Tasks](#maintenance-tasks)
6. [APEX Operations](#apex-operations)

---

## User Management

### Create New User in APEX
```sql
-- Create APEX workspace user
BEGIN
    apex_util.create_user(
        p_user_name                    => 'john.doe',
        p_email_address                => 'john.doe@company.com',
        p_web_password                 => 'TempPassword123!',
        p_change_password_on_first_use => 'Y',
        p_first_name                   => 'John',
        p_last_name                    => 'Doe'
    );
END;
/
```

### Add User to Team
```sql
-- Add user as Editor
INSERT INTO team_members (team_id, username, email, member_role)
VALUES (
    1,                              -- team_id
    'john.doe',                     -- username (must match APEX user)
    'john.doe@company.com',
    'EDITOR'                        -- ADMIN, MANAGER, EDITOR, or VIEWER
);
COMMIT;
```

### Change User Role
```sql
-- Update user role
UPDATE team_members
SET member_role = 'MANAGER',
    updated_by = USER,
    updated_date = SYSTIMESTAMP
WHERE username = 'john.doe'
  AND team_id = 1;
COMMIT;
```

### Deactivate User
```sql
-- Soft delete - keep history
UPDATE team_members
SET is_active = 'N',
    updated_by = USER,
    updated_date = SYSTIMESTAMP
WHERE username = 'john.doe';
COMMIT;

-- Hard delete - remove completely (not recommended)
DELETE FROM team_members WHERE username = 'john.doe';
COMMIT;
```

### List All Users and Their Roles
```sql
SELECT 
    tm.username,
    tm.email,
    t.team_name,
    tm.member_role,
    tm.is_active,
    TO_CHAR(tm.created_date, 'MM/DD/YYYY') as member_since
FROM team_members tm
JOIN teams t ON tm.team_id = t.team_id
ORDER BY tm.username, t.team_name;
```

---

## Team Management

### Create New Team
```sql
INSERT INTO teams (team_name, team_description, is_active)
VALUES (
    'Mobile Development Team',
    'Team responsible for iOS and Android applications',
    'Y'
);
COMMIT;
```

### Add Multiple Members to Team
```sql
-- Add several members at once
INSERT ALL
    INTO team_members (team_id, username, email, member_role) 
    VALUES (2, 'alice.smith', 'alice@company.com', 'MANAGER')
    INTO team_members (team_id, username, email, member_role) 
    VALUES (2, 'bob.jones', 'bob@company.com', 'EDITOR')
    INTO team_members (team_id, username, email, member_role) 
    VALUES (2, 'carol.white', 'carol@company.com', 'EDITOR')
    INTO team_members (team_id, username, email, member_role) 
    VALUES (2, 'david.brown', 'david@company.com', 'VIEWER')
SELECT * FROM dual;
COMMIT;
```

### Get Team Statistics
```sql
SELECT 
    t.team_name,
    COUNT(DISTINCT tm.username) as total_members,
    COUNT(DISTINCT CASE WHEN tm.member_role = 'MANAGER' THEN tm.username END) as managers,
    COUNT(DISTINCT CASE WHEN tm.member_role = 'EDITOR' THEN tm.username END) as editors,
    COUNT(DISTINCT jt.ticket_id) as total_tickets,
    COUNT(DISTINCT CASE WHEN jt.status = 'Done' THEN jt.ticket_id END) as completed_tickets,
    SUM(jt.story_points) as total_story_points
FROM teams t
LEFT JOIN team_members tm ON t.team_id = tm.team_id AND tm.is_active = 'Y'
LEFT JOIN jira_tickets jt ON t.team_id = jt.team_id AND jt.is_active = 'Y'
GROUP BY t.team_name
ORDER BY t.team_name;
```

---

## Ticket Operations

### Create New Ticket
```sql
INSERT INTO jira_tickets (
    team_id,
    jira_key,
    ticket_summary,
    ticket_description,
    ticket_type,
    priority,
    status,
    assignee,
    reporter,
    sprint,
    story_points
) VALUES (
    1,                                  -- team_id
    'DEV-' || TO_CHAR(SYSDATE, 'YYYYMMDD-HH24MISS'),  -- unique key
    'Implement user authentication',
    'Add OAuth2 authentication to the application',
    'Story',
    'High',
    'To Do',
    'john.doe',
    'jane.manager',
    'Sprint 24',
    8
);
COMMIT;
```

### Bulk Create Tickets from CSV Data
```sql
-- Assuming you have a temporary table with CSV data
INSERT INTO jira_tickets (
    team_id, jira_key, ticket_summary, ticket_type, 
    priority, status, assignee, story_points
)
SELECT 
    1,                              -- team_id
    jira_key,
    summary,
    ticket_type,
    priority,
    'To Do',                        -- default status
    assignee,
    story_points
FROM csv_import_temp
WHERE jira_key IS NOT NULL;
COMMIT;
```

### Update Ticket Status
```sql
-- Simple update
UPDATE jira_tickets
SET status = 'In Progress',
    updated_by = USER,
    updated_date = SYSTIMESTAMP
WHERE jira_key = 'DEV-101';
COMMIT;

-- Update with snapshot creation
BEGIN
    UPDATE jira_tickets
    SET status = 'Done'
    WHERE jira_key = 'DEV-101';
    
    jira_ticket_pkg.create_weekly_snapshot(
        (SELECT ticket_id FROM jira_tickets WHERE jira_key = 'DEV-101')
    );
    COMMIT;
END;
/
```

### Update Multiple Tickets
```sql
-- Update all tickets in a sprint
UPDATE jira_tickets
SET status = 'In Progress',
    updated_by = USER,
    updated_date = SYSTIMESTAMP
WHERE sprint = 'Sprint 24'
  AND status = 'To Do'
  AND team_id = 1;
COMMIT;
```

### Move Ticket to Different Team
```sql
-- Reassign ticket to different team
UPDATE jira_tickets
SET team_id = 2,
    updated_by = USER,
    updated_date = SYSTIMESTAMP
WHERE jira_key = 'DEV-101';
COMMIT;
```

### Archive/Close Ticket
```sql
-- Soft close - mark as inactive
UPDATE jira_tickets
SET is_active = 'N',
    status = 'Closed',
    updated_by = USER,
    updated_date = SYSTIMESTAMP
WHERE jira_key = 'DEV-101';
COMMIT;
```

---

## Reporting Queries

### Current Week Dashboard
```sql
SELECT 
    t.team_name,
    COUNT(*) as ticket_count,
    COUNT(CASE WHEN jt.status = 'Done' THEN 1 END) as completed,
    COUNT(CASE WHEN jt.status = 'In Progress' THEN 1 END) as in_progress,
    COUNT(CASE WHEN jt.status = 'To Do' THEN 1 END) as todo,
    SUM(jt.story_points) as total_points,
    SUM(CASE WHEN jt.status = 'Done' THEN jt.story_points ELSE 0 END) as completed_points
FROM jira_tickets jt
JOIN teams t ON jt.team_id = t.team_id
WHERE jt.week_number = TO_NUMBER(TO_CHAR(SYSDATE, 'IW'))
  AND jt.week_year = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'))
  AND jt.is_active = 'Y'
GROUP BY t.team_name;
```

### Team Velocity (Last 4 Weeks)
```sql
WITH last_4_weeks AS (
    SELECT DISTINCT week_year, week_number, week_start_date
    FROM jira_ticket_history
    WHERE snapshot_date >= SYSDATE - 28
    ORDER BY week_year DESC, week_number DESC
    FETCH FIRST 4 ROWS ONLY
)
SELECT 
    t.team_name,
    h.week_number,
    h.week_year,
    h.week_start_date,
    SUM(CASE WHEN h.status = 'Done' THEN h.story_points ELSE 0 END) as completed_points,
    COUNT(CASE WHEN h.status = 'Done' THEN 1 END) as completed_tickets
FROM jira_ticket_history h
JOIN jira_tickets jt ON h.ticket_id = jt.ticket_id
JOIN teams t ON jt.team_id = t.team_id
JOIN last_4_weeks lw ON h.week_year = lw.week_year AND h.week_number = lw.week_number
GROUP BY t.team_name, h.week_number, h.week_year, h.week_start_date
ORDER BY h.week_year DESC, h.week_number DESC, t.team_name;
```

### Individual Performance Report
```sql
SELECT 
    assignee,
    COUNT(*) as total_assigned,
    COUNT(CASE WHEN status = 'Done' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'In Progress' THEN 1 END) as in_progress,
    SUM(story_points) as total_points,
    SUM(CASE WHEN status = 'Done' THEN story_points ELSE 0 END) as completed_points,
    ROUND(AVG(time_spent), 2) as avg_hours_per_ticket
FROM jira_tickets
WHERE team_id = 1
  AND is_active = 'Y'
  AND assignee IS NOT NULL
GROUP BY assignee
ORDER BY completed_points DESC;
```

### Priority Distribution
```sql
SELECT 
    priority,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
    SUM(story_points) as total_points
FROM jira_tickets
WHERE team_id = 1
  AND is_active = 'Y'
GROUP BY priority
ORDER BY 
    CASE priority
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'Low' THEN 4
        WHEN 'Trivial' THEN 5
    END;
```

### Sprint Burndown
```sql
SELECT 
    week_number,
    week_start_date,
    SUM(story_points) as total_points,
    SUM(CASE WHEN status IN ('Done', 'Closed') THEN story_points ELSE 0 END) as completed_points,
    SUM(story_points) - SUM(CASE WHEN status IN ('Done', 'Closed') THEN story_points ELSE 0 END) as remaining_points
FROM jira_ticket_history
WHERE sprint = 'Sprint 24'
  AND week_year = 2026
GROUP BY week_number, week_start_date
ORDER BY week_number;
```

### Tickets Created vs Resolved
```sql
SELECT 
    TO_CHAR(created_date, 'YYYY-MM') as month,
    COUNT(*) as created,
    COUNT(CASE WHEN status IN ('Done', 'Closed') THEN 1 END) as resolved,
    COUNT(*) - COUNT(CASE WHEN status IN ('Done', 'Closed') THEN 1 END) as net_change
FROM jira_tickets
WHERE team_id = 1
  AND created_date >= ADD_MONTHS(SYSDATE, -6)
GROUP BY TO_CHAR(created_date, 'YYYY-MM')
ORDER BY month;
```

---

## Maintenance Tasks

### Create Weekly Snapshots Manually
```sql
-- Create snapshots for all active tickets
BEGIN
    jira_ticket_pkg.create_all_weekly_snapshots;
END;
/

-- Create snapshot for specific ticket
BEGIN
    jira_ticket_pkg.create_weekly_snapshot(
        p_ticket_id => 123  -- ticket_id
    );
END;
/
```

### Clean Up Old History (Archive)
```sql
-- Archive history older than 1 year
CREATE TABLE jira_ticket_history_archive AS
SELECT * FROM jira_ticket_history
WHERE snapshot_date < ADD_MONTHS(SYSDATE, -12);

-- Verify archive
SELECT 
    TO_CHAR(snapshot_date, 'YYYY-MM') as month,
    COUNT(*) as record_count
FROM jira_ticket_history_archive
GROUP BY TO_CHAR(snapshot_date, 'YYYY-MM')
ORDER BY month;

-- Delete archived records from main table
DELETE FROM jira_ticket_history
WHERE snapshot_date < ADD_MONTHS(SYSDATE, -12);
COMMIT;
```

### Rebuild Indexes
```sql
-- Rebuild all indexes for optimal performance
BEGIN
    FOR idx IN (
        SELECT index_name 
        FROM user_indexes 
        WHERE table_name IN ('JIRA_TICKETS', 'JIRA_TICKET_HISTORY', 'TEAMS', 'TEAM_MEMBERS')
    ) LOOP
        EXECUTE IMMEDIATE 'ALTER INDEX ' || idx.index_name || ' REBUILD';
    END LOOP;
END;
/
```

### Update Statistics
```sql
-- Gather statistics for all tables
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(
        ownname => USER,
        cascade => TRUE,
        options => 'GATHER AUTO'
    );
END;
/

-- Or for specific tables
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'JIRA_TICKETS');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'JIRA_TICKET_HISTORY');
END;
/
```

### Check Data Integrity
```sql
-- Find tickets without team
SELECT * FROM jira_tickets WHERE team_id IS NULL;

-- Find orphaned history records
SELECT h.* 
FROM jira_ticket_history h
LEFT JOIN jira_tickets t ON h.ticket_id = t.ticket_id
WHERE t.ticket_id IS NULL;

-- Find users in team_members but not in APEX
SELECT tm.username
FROM team_members tm
WHERE NOT EXISTS (
    SELECT 1 
    FROM apex_workspace_apex_users au
    WHERE UPPER(au.user_name) = UPPER(tm.username)
);
```

---

## APEX Operations

### Get Application ID
```sql
SELECT application_id, application_name, owner
FROM apex_applications
WHERE application_name LIKE '%Jira%';
```

### View Application Activity
```sql
SELECT 
    userid,
    TO_CHAR(time_stamp, 'YYYY-MM-DD HH24:MI:SS') as access_time,
    apex_session_id,
    component_type,
    component_name
FROM apex_activity_log
WHERE application_id = :APP_ID
  AND time_stamp > SYSDATE - 1
ORDER BY time_stamp DESC;
```

### View Debug Messages
```sql
SELECT 
    TO_CHAR(time_stamp, 'HH24:MI:SS.FF3') as time,
    message_level,
    message_text
FROM apex_debug_messages
WHERE session_id = :SESSION_ID
  AND application_id = :APP_ID
ORDER BY time_stamp;
```

### Reset User Password
```sql
BEGIN
    apex_util.edit_user(
        p_user_name => 'john.doe',
        p_web_password => 'NewPassword123!',
        p_change_password_on_first_use => 'Y'
    );
    COMMIT;
END;
/
```

### Export Application (via SQL)
```sql
-- Generate export file
BEGIN
    apex_application_install.generate_application_id;
    apex_application_install.generate_offset;
    apex_application_install.set_workspace_id;
    apex_application_install.set_application_id(:APP_ID);
    apex_application_install.set_schema(USER);
END;
/
```

---

## Useful Queries for Monitoring

### Check Scheduler Job Status
```sql
SELECT 
    job_name,
    enabled,
    state,
    TO_CHAR(last_start_date, 'MM/DD/YYYY HH24:MI:SS') as last_run,
    TO_CHAR(next_run_date, 'MM/DD/YYYY HH24:MI:SS') as next_run,
    failure_count,
    run_count
FROM user_scheduler_jobs
WHERE job_name LIKE '%JIRA%';
```

### Check Table Sizes
```sql
SELECT 
    table_name,
    num_rows,
    blocks,
    ROUND(blocks * 8 / 1024, 2) as size_mb,
    last_analyzed
FROM user_tables
WHERE table_name IN ('JIRA_TICKETS', 'JIRA_TICKET_HISTORY', 'TEAMS', 'TEAM_MEMBERS')
ORDER BY blocks DESC;
```

### Find Slow Queries (if SQL Monitoring is enabled)
```sql
SELECT 
    sql_id,
    sql_text,
    executions,
    ROUND(elapsed_time/1000000, 2) as elapsed_sec,
    ROUND(elapsed_time/executions/1000000, 4) as avg_elapsed_sec
FROM v$sql
WHERE sql_text LIKE '%jira_tickets%'
  AND sql_text NOT LIKE '%v$sql%'
ORDER BY elapsed_time DESC
FETCH FIRST 10 ROWS ONLY;
```

---

## Best Practices

### 1. Always Use Transactions
```sql
-- Good practice
BEGIN
    UPDATE jira_tickets SET status = 'Done' WHERE jira_key = 'DEV-101';
    jira_ticket_pkg.create_weekly_snapshot(123);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
```

### 2. Use Bind Variables
```sql
-- Instead of
UPDATE jira_tickets SET status = 'Done' WHERE team_id = 1;

-- Use (in APEX)
UPDATE jira_tickets SET status = 'Done' WHERE team_id = :APP_USER_TEAM_ID;
```

### 3. Create Indexes for Frequently Filtered Columns
```sql
-- Add index for custom filtering
CREATE INDEX idx_tickets_custom ON jira_tickets(custom_field);
```

### 4. Regular Maintenance Schedule
```sql
-- Weekly: Gather statistics
-- Monthly: Archive old data
-- Quarterly: Review and optimize indexes
-- Yearly: Review and archive history beyond retention period
```

---

## Emergency Procedures

### Restore Accidentally Deleted Tickets
```sql
-- If using flashback (within undo retention)
SELECT * FROM jira_tickets AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' HOUR)
WHERE jira_key = 'DEV-101';

-- Insert back if needed
INSERT INTO jira_tickets
SELECT * FROM jira_tickets AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '1' HOUR)
WHERE jira_key = 'DEV-101';
COMMIT;
```

### Unlock Locked Accounts
```sql
-- Unlock APEX user
BEGIN
    apex_util.unlock_account(
        p_user_name => 'john.doe'
    );
    COMMIT;
END;
/
```

### Reset Application
```sql
-- Clear all session state for application
BEGIN
    apex_util.reset_authorizations;
END;
/
```

---

**Need more help?** Refer to the main documentation files:
- `05_deployment_guide.md` - Full deployment instructions
- `04_apex_pages_guide.md` - APEX configuration details
- `README.md` - Overview and architecture
