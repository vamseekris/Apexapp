-- ============================================================================
-- Oracle APEX Application Setup - Jira Ticket Tracking
-- ============================================================================
-- This script contains SQL commands to help set up the APEX application
-- Most APEX configuration will be done through the APEX UI
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Application-Level Items (Run in SQL Workshop)
-- ============================================================================

-- These will be referenced in APEX as application items
-- You'll create these in APEX Builder under Shared Components > Application Items
/*
Create the following Application Items in APEX:
- APP_USER_NAME (to store current username)
- APP_USER_TEAM_ID (to store current user's team)
- APP_USER_ROLE (to store current user's role)
*/

-- ============================================================================
-- STEP 2: Create Authorization Schemes (Run in APEX Builder)
-- ============================================================================

/*
In APEX Builder, go to Shared Components > Authorization Schemes

Create the following schemes:

1. Can View
   Type: PL/SQL Function Returning Boolean
   PL/SQL Function Body:
   BEGIN
       RETURN jira_ticket_pkg.has_team_access(
           :APP_USER_NAME, 
           :APP_USER_TEAM_ID
       );
   END;

2. Can Edit
   Type: PL/SQL Function Returning Boolean
   PL/SQL Function Body:
   BEGIN
       RETURN jira_ticket_pkg.can_edit(
           :APP_USER_NAME, 
           :APP_USER_TEAM_ID
       );
   END;

3. Can Manage
   Type: PL/SQL Function Returning Boolean
   PL/SQL Function Body:
   BEGIN
       RETURN jira_ticket_pkg.can_manage(
           :APP_USER_NAME, 
           :APP_USER_TEAM_ID
       );
   END;

4. Is Admin
   Type: PL/SQL Function Returning Boolean
   PL/SQL Function Body:
   BEGIN
       RETURN jira_ticket_pkg.get_user_role(
           :APP_USER_NAME, 
           :APP_USER_TEAM_ID
       ) = 'ADMIN';
   END;
*/

-- ============================================================================
-- STEP 3: Create Application Process to Set User Context
-- ============================================================================

/*
In APEX Builder, create an Application Process:
Name: Set User Context
Process Point: On New Session: Before Header
Process Type: Execute Code

PL/SQL Code:
*/

DECLARE
    v_team_id NUMBER;
    v_role VARCHAR2(50);
BEGIN
    -- Set username
    :APP_USER_NAME := :APP_USER;
    
    -- Get user's primary team (you may want to add team selection)
    BEGIN
        SELECT team_id, member_role
        INTO v_team_id, v_role
        FROM team_members
        WHERE username = :APP_USER
          AND is_active = 'Y'
          AND ROWNUM = 1;
          
        :APP_USER_TEAM_ID := v_team_id;
        :APP_USER_ROLE := v_role;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            :APP_USER_TEAM_ID := NULL;
            :APP_USER_ROLE := NULL;
    END;
END;

-- ============================================================================
-- STEP 4: Create RESTful Services (Optional - for Jira Integration)
-- ============================================================================

-- You can create REST APIs to accept data from Jira webhooks
-- This would be configured in APEX Builder > SQL Workshop > RESTful Services

-- ============================================================================
-- STEP 5: Sample Queries for APEX Pages
-- ============================================================================

-- Query for Main Ticket Dashboard (Interactive Report/Grid)
/*
SELECT 
    ticket_id,
    team_name,
    jira_key,
    ticket_summary,
    ticket_type,
    priority,
    status,
    assignee,
    sprint,
    story_points,
    week_number || '/' || week_year as week,
    TO_CHAR(week_start_date, 'MM/DD') || ' - ' || TO_CHAR(week_end_date, 'MM/DD') as week_range,
    updated_by,
    TO_CHAR(updated_date, 'MM/DD/YYYY HH24:MI') as last_updated
FROM v_jira_tickets_dashboard
WHERE team_id = :APP_USER_TEAM_ID
ORDER BY updated_date DESC;
*/

-- Query for Weekly Status Chart
/*
SELECT 
    week_start_date as week,
    status,
    ticket_count
FROM v_weekly_status_report
WHERE team_name = (SELECT team_name FROM teams WHERE team_id = :APP_USER_TEAM_ID)
  AND week_year = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'))
ORDER BY week_start_date, status;
*/

-- Query for Team Performance Dashboard
/*
SELECT 
    assignee,
    COUNT(*) as total_tickets,
    SUM(CASE WHEN status = 'Done' THEN 1 ELSE 0 END) as completed,
    SUM(story_points) as total_points,
    ROUND(SUM(time_spent), 2) as hours_spent
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
  AND is_active = 'Y'
  AND week_number = TO_NUMBER(TO_CHAR(SYSDATE, 'IW'))
GROUP BY assignee
ORDER BY completed DESC;
*/

-- ============================================================================
-- STEP 6: Create List of Values (LOVs)
-- ============================================================================

-- In APEX Builder > Shared Components > List of Values, create:

-- 1. LOV_TEAMS
SELECT team_id as d, team_name as r
FROM teams
WHERE is_active = 'Y'
ORDER BY team_name;

-- 2. LOV_STATUS
SELECT DISTINCT status as d, status as r
FROM jira_tickets
ORDER BY status;

-- 3. LOV_TICKET_TYPE
SELECT column_value as d, column_value as r
FROM TABLE(sys.odcivarchar2list('Story','Bug','Task','Epic','Sub-task','Improvement'))
ORDER BY column_value;

-- 4. LOV_PRIORITY
SELECT column_value as d, column_value as r
FROM TABLE(sys.odcivarchar2list('Critical','High','Medium','Low','Trivial'))
ORDER BY 
    CASE column_value
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'Low' THEN 4
        WHEN 'Trivial' THEN 5
    END;

-- 5. LOV_MEMBER_ROLE
SELECT column_value as d, column_value as r
FROM TABLE(sys.odcivarchar2list('ADMIN','MANAGER','EDITOR','VIEWER'))
ORDER BY 
    CASE column_value
        WHEN 'ADMIN' THEN 1
        WHEN 'MANAGER' THEN 2
        WHEN 'EDITOR' THEN 3
        WHEN 'VIEWER' THEN 4
    END;

-- 6. LOV_ASSIGNEES
SELECT DISTINCT assignee as d, assignee as r
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
  AND assignee IS NOT NULL
ORDER BY assignee;

-- ============================================================================
-- STEP 7: Sample Validation Function
-- ============================================================================

-- Use this in form validations to check edit permissions
CREATE OR REPLACE FUNCTION apex_validate_edit_permission(
    p_username VARCHAR2,
    p_team_id NUMBER
) RETURN VARCHAR2 IS
BEGIN
    IF jira_ticket_pkg.can_edit(p_username, p_team_id) THEN
        RETURN NULL; -- Validation passed
    ELSE
        RETURN 'You do not have permission to edit tickets for this team.';
    END IF;
END;
/

-- ============================================================================
-- STEP 8: Create Scheduled Job for Weekly Snapshots (Optional)
-- ============================================================================

-- Run this in SQL Workshop to create a weekly job
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'WEEKLY_TICKET_SNAPSHOT_JOB',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN jira_ticket_pkg.create_all_weekly_snapshots; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=WEEKLY; BYDAY=MON; BYHOUR=1; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Create weekly snapshots of all Jira tickets every Monday at 1 AM'
    );
END;
/

-- To check the job status
SELECT job_name, enabled, state, last_start_date, next_run_date
FROM user_scheduler_jobs
WHERE job_name = 'WEEKLY_TICKET_SNAPSHOT_JOB';

-- ============================================================================
-- STEP 9: Grant Necessary Privileges (if needed)
-- ============================================================================

-- If you have separate APEX workspace schema, grant privileges
/*
GRANT SELECT, INSERT, UPDATE, DELETE ON teams TO apex_workspace_schema;
GRANT SELECT, INSERT, UPDATE, DELETE ON team_members TO apex_workspace_schema;
GRANT SELECT, INSERT, UPDATE, DELETE ON jira_tickets TO apex_workspace_schema;
GRANT SELECT, INSERT, UPDATE, DELETE ON jira_ticket_history TO apex_workspace_schema;
GRANT SELECT ON v_jira_tickets_dashboard TO apex_workspace_schema;
GRANT SELECT ON v_weekly_status_report TO apex_workspace_schema;
GRANT EXECUTE ON jira_ticket_pkg TO apex_workspace_schema;
*/

-- ============================================================================
-- Success Message
-- ============================================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('APEX Setup SQL completed successfully!');
    DBMS_OUTPUT.PUT_LINE('Next steps:');
    DBMS_OUTPUT.PUT_LINE('1. Create APEX Application');
    DBMS_OUTPUT.PUT_LINE('2. Set up Application Items');
    DBMS_OUTPUT.PUT_LINE('3. Create Authorization Schemes');
    DBMS_OUTPUT.PUT_LINE('4. Create Application Pages (see next document)');
END;
/
