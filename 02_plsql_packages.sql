-- ============================================================================
-- PL/SQL Package: JIRA_TICKET_PKG
-- Business Logic and Security Functions
-- ============================================================================

CREATE OR REPLACE PACKAGE jira_ticket_pkg AS
    
    -- Role constants
    c_role_admin    CONSTANT VARCHAR2(20) := 'ADMIN';
    c_role_manager  CONSTANT VARCHAR2(20) := 'MANAGER';
    c_role_editor   CONSTANT VARCHAR2(20) := 'EDITOR';
    c_role_viewer   CONSTANT VARCHAR2(20) := 'VIEWER';
    
    -- Check if user has access to a team
    FUNCTION has_team_access(
        p_username  IN VARCHAR2,
        p_team_id   IN NUMBER
    ) RETURN BOOLEAN;
    
    -- Get user role for a team
    FUNCTION get_user_role(
        p_username  IN VARCHAR2,
        p_team_id   IN NUMBER
    ) RETURN VARCHAR2;
    
    -- Check if user can edit (ADMIN, MANAGER, or EDITOR)
    FUNCTION can_edit(
        p_username  IN VARCHAR2,
        p_team_id   IN NUMBER
    ) RETURN BOOLEAN;
    
    -- Check if user can manage team (ADMIN or MANAGER)
    FUNCTION can_manage(
        p_username  IN VARCHAR2,
        p_team_id   IN NUMBER
    ) RETURN BOOLEAN;
    
    -- Calculate week number and dates
    PROCEDURE calculate_week_info(
        p_date          IN  DATE,
        p_week_number   OUT NUMBER,
        p_week_year     OUT NUMBER,
        p_week_start    OUT DATE,
        p_week_end      OUT DATE
    );
    
    -- Create weekly snapshot
    PROCEDURE create_weekly_snapshot(
        p_ticket_id IN NUMBER
    );
    
    -- Bulk create snapshots for all active tickets
    PROCEDURE create_all_weekly_snapshots;
    
    -- Update ticket with automatic week calculation
    PROCEDURE update_ticket_status(
        p_ticket_id IN NUMBER,
        p_status    IN VARCHAR2,
        p_username  IN VARCHAR2
    );
    
END jira_ticket_pkg;
/

CREATE OR REPLACE PACKAGE BODY jira_ticket_pkg AS
    
    -- ========================================================================
    -- Check if user has access to a team
    -- ========================================================================
    FUNCTION has_team_access(
        p_username  IN VARCHAR2,
        p_team_id   IN NUMBER
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM team_members
        WHERE username = p_username
          AND team_id = p_team_id
          AND is_active = 'Y';
          
        RETURN v_count > 0;
    END has_team_access;
    
    -- ========================================================================
    -- Get user role for a team
    -- ========================================================================
    FUNCTION get_user_role(
        p_username  IN VARCHAR2,
        p_team_id   IN NUMBER
    ) RETURN VARCHAR2 IS
        v_role VARCHAR2(50);
    BEGIN
        SELECT member_role
        INTO v_role
        FROM team_members
        WHERE username = p_username
          AND team_id = p_team_id
          AND is_active = 'Y';
          
        RETURN v_role;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_user_role;
    
    -- ========================================================================
    -- Check if user can edit
    -- ========================================================================
    FUNCTION can_edit(
        p_username  IN VARCHAR2,
        p_team_id   IN NUMBER
    ) RETURN BOOLEAN IS
        v_role VARCHAR2(50);
    BEGIN
        v_role := get_user_role(p_username, p_team_id);
        RETURN v_role IN (c_role_admin, c_role_manager, c_role_editor);
    END can_edit;
    
    -- ========================================================================
    -- Check if user can manage team
    -- ========================================================================
    FUNCTION can_manage(
        p_username  IN VARCHAR2,
        p_team_id   IN NUMBER
    ) RETURN BOOLEAN IS
        v_role VARCHAR2(50);
    BEGIN
        v_role := get_user_role(p_username, p_team_id);
        RETURN v_role IN (c_role_admin, c_role_manager);
    END can_manage;
    
    -- ========================================================================
    -- Calculate week number and dates
    -- ========================================================================
    PROCEDURE calculate_week_info(
        p_date          IN  DATE,
        p_week_number   OUT NUMBER,
        p_week_year     OUT NUMBER,
        p_week_start    OUT DATE,
        p_week_end      OUT DATE
    ) IS
    BEGIN
        p_week_number := TO_NUMBER(TO_CHAR(p_date, 'IW'));
        p_week_year := TO_NUMBER(TO_CHAR(p_date, 'IYYY'));
        p_week_start := TRUNC(p_date, 'IW');
        p_week_end := TRUNC(p_date, 'IW') + 6;
    END calculate_week_info;
    
    -- ========================================================================
    -- Create weekly snapshot
    -- ========================================================================
    PROCEDURE create_weekly_snapshot(
        p_ticket_id IN NUMBER
    ) IS
        v_week_number   NUMBER;
        v_week_year     NUMBER;
        v_week_start    DATE;
        v_week_end      DATE;
    BEGIN
        calculate_week_info(SYSDATE, v_week_number, v_week_year, v_week_start, v_week_end);
        
        INSERT INTO jira_ticket_history (
            ticket_id, jira_key, status, assignee, sprint,
            story_points, time_spent, remaining_estimate,
            week_number, week_year, week_start_date, week_end_date
        )
        SELECT 
            ticket_id, jira_key, status, assignee, sprint,
            story_points, time_spent, remaining_estimate,
            v_week_number, v_week_year, v_week_start, v_week_end
        FROM jira_tickets
        WHERE ticket_id = p_ticket_id
          AND is_active = 'Y';
        
        COMMIT;
    END create_weekly_snapshot;
    
    -- ========================================================================
    -- Bulk create snapshots for all active tickets
    -- ========================================================================
    PROCEDURE create_all_weekly_snapshots IS
        v_week_number   NUMBER;
        v_week_year     NUMBER;
        v_week_start    DATE;
        v_week_end      DATE;
        v_count         NUMBER := 0;
    BEGIN
        calculate_week_info(SYSDATE, v_week_number, v_week_year, v_week_start, v_week_end);
        
        FOR ticket_rec IN (
            SELECT ticket_id, jira_key, status, assignee, sprint,
                   story_points, time_spent, remaining_estimate
            FROM jira_tickets
            WHERE is_active = 'Y'
        ) LOOP
            INSERT INTO jira_ticket_history (
                ticket_id, jira_key, status, assignee, sprint,
                story_points, time_spent, remaining_estimate,
                week_number, week_year, week_start_date, week_end_date
            ) VALUES (
                ticket_rec.ticket_id, ticket_rec.jira_key, ticket_rec.status, 
                ticket_rec.assignee, ticket_rec.sprint,
                ticket_rec.story_points, ticket_rec.time_spent, ticket_rec.remaining_estimate,
                v_week_number, v_week_year, v_week_start, v_week_end
            );
            
            v_count := v_count + 1;
        END LOOP;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Created ' || v_count || ' weekly snapshots');
    END create_all_weekly_snapshots;
    
    -- ========================================================================
    -- Update ticket status
    -- ========================================================================
    PROCEDURE update_ticket_status(
        p_ticket_id IN NUMBER,
        p_status    IN VARCHAR2,
        p_username  IN VARCHAR2
    ) IS
        v_week_number   NUMBER;
        v_week_year     NUMBER;
        v_week_start    DATE;
        v_week_end      DATE;
    BEGIN
        calculate_week_info(SYSDATE, v_week_number, v_week_year, v_week_start, v_week_end);
        
        UPDATE jira_tickets
        SET status = p_status,
            week_number = v_week_number,
            week_year = v_week_year,
            week_start_date = v_week_start,
            week_end_date = v_week_end,
            updated_by = p_username,
            updated_date = SYSTIMESTAMP
        WHERE ticket_id = p_ticket_id;
        
        -- Create snapshot after status change
        create_weekly_snapshot(p_ticket_id);
        
        COMMIT;
    END update_ticket_status;
    
END jira_ticket_pkg;
/

-- ============================================================================
-- Create Database Triggers
-- ============================================================================

-- Trigger to automatically calculate week info on insert/update
CREATE OR REPLACE TRIGGER jira_tickets_week_trg
BEFORE INSERT OR UPDATE ON jira_tickets
FOR EACH ROW
DECLARE
    v_week_number   NUMBER;
    v_week_year     NUMBER;
    v_week_start    DATE;
    v_week_end      DATE;
BEGIN
    -- Calculate week info if not provided
    IF :NEW.week_start_date IS NULL OR :NEW.week_end_date IS NULL THEN
        jira_ticket_pkg.calculate_week_info(
            NVL(:NEW.updated_date, SYSDATE),
            v_week_number,
            v_week_year,
            v_week_start,
            v_week_end
        );
        
        :NEW.week_number := v_week_number;
        :NEW.week_year := v_week_year;
        :NEW.week_start_date := v_week_start;
        :NEW.week_end_date := v_week_end;
    END IF;
    
    -- Set audit fields
    IF INSERTING THEN
        :NEW.created_by := NVL(:NEW.created_by, USER);
        :NEW.created_date := NVL(:NEW.created_date, SYSTIMESTAMP);
    END IF;
    
    :NEW.updated_by := USER;
    :NEW.updated_date := SYSTIMESTAMP;
END;
/

-- Trigger for teams audit
CREATE OR REPLACE TRIGGER teams_audit_trg
BEFORE INSERT OR UPDATE ON teams
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := NVL(:NEW.created_by, USER);
        :NEW.created_date := NVL(:NEW.created_date, SYSTIMESTAMP);
    END IF;
    :NEW.updated_by := USER;
    :NEW.updated_date := SYSTIMESTAMP;
END;
/

-- Trigger for team_members audit
CREATE OR REPLACE TRIGGER team_members_audit_trg
BEFORE INSERT OR UPDATE ON team_members
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := NVL(:NEW.created_by, USER);
        :NEW.created_date := NVL(:NEW.created_date, SYSTIMESTAMP);
    END IF;
    :NEW.updated_by := USER;
    :NEW.updated_date := SYSTIMESTAMP;
END;
/

-- ============================================================================
-- Create Views for APEX Application
-- ============================================================================

-- View for ticket dashboard with team information
CREATE OR REPLACE VIEW v_jira_tickets_dashboard AS
SELECT 
    t.ticket_id,
    t.team_id,
    tm.team_name,
    t.jira_key,
    t.jira_id,
    t.ticket_summary,
    t.ticket_type,
    t.priority,
    t.status,
    t.assignee,
    t.reporter,
    t.sprint,
    t.story_points,
    t.week_number,
    t.week_year,
    t.week_start_date,
    t.week_end_date,
    t.created_date,
    t.updated_date,
    t.updated_by
FROM jira_tickets t
JOIN teams tm ON t.team_id = tm.team_id
WHERE t.is_active = 'Y';

-- View for weekly status report
CREATE OR REPLACE VIEW v_weekly_status_report AS
SELECT 
    h.week_number,
    h.week_year,
    h.week_start_date,
    h.week_end_date,
    t.team_name,
    h.status,
    COUNT(*) as ticket_count,
    SUM(h.story_points) as total_story_points,
    SUM(h.time_spent) as total_time_spent
FROM jira_ticket_history h
JOIN jira_tickets jt ON h.ticket_id = jt.ticket_id
JOIN teams t ON jt.team_id = t.team_id
GROUP BY h.week_number, h.week_year, h.week_start_date, h.week_end_date, t.team_name, h.status
ORDER BY h.week_year DESC, h.week_number DESC, t.team_name, h.status;

COMMIT;
