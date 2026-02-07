# Oracle APEX Application - Page Configuration Guide
# Jira Ticket Tracking System

## Application Structure

### Page Hierarchy
```
Application: Jira Ticket Tracker
├── Page 0: Global Page (Navigation)
├── Page 1: Home Dashboard
├── Page 2: Ticket List (Interactive Grid)
├── Page 3: Ticket Details (Form)
├── Page 4: Weekly Status Report
├── Page 5: Team Management
├── Page 6: User Administration
└── Page 7: Analytics & Charts
```

---

## Page 0: Global Page (Navigation Menu)

### Purpose
Define shared navigation and global elements

### Configuration
1. **Create Navigation Menu** (Shared Components > Navigation Menu)
   - List Name: `Desktop Navigation Menu`
   - List Entries:
     * Home (Target: Page 1, Icon: fa-home)
     * Tickets (Target: Page 2, Icon: fa-ticket)
     * Weekly Report (Target: Page 4, Icon: fa-calendar)
     * Team Management (Target: Page 5, Icon: fa-users, Authorization: Can Manage)
     * Analytics (Target: Page 7, Icon: fa-bar-chart)

2. **Navigation Bar**
   - Add User Menu (Profile, Settings, Logout)
   - Display: `&APP_USER_NAME.` with role badge `&APP_USER_ROLE.`

---

## Page 1: Home Dashboard

### Purpose
Landing page with key metrics and quick access

### Regions

#### Region 1: Key Metrics (Cards)
**Type:** Cards
**Source Type:** SQL Query
```sql
SELECT 
    'Total Active Tickets' as title,
    COUNT(*) as value,
    'fa-ticket' as icon,
    'u-color-1' as color
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
  AND is_active = 'Y'
UNION ALL
SELECT 
    'In Progress',
    COUNT(*),
    'fa-spinner',
    'u-color-2'
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
  AND status = 'In Progress'
  AND is_active = 'Y'
UNION ALL
SELECT 
    'This Week',
    COUNT(*),
    'fa-calendar',
    'u-color-3'
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
  AND week_number = TO_NUMBER(TO_CHAR(SYSDATE, 'IW'))
  AND week_year = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'))
  AND is_active = 'Y'
UNION ALL
SELECT 
    'Story Points',
    NVL(SUM(story_points), 0),
    'fa-line-chart',
    'u-color-4'
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
  AND week_number = TO_NUMBER(TO_CHAR(SYSDATE, 'IW'))
  AND is_active = 'Y';
```

#### Region 2: Recent Updates
**Type:** Classic Report
**Source:**
```sql
SELECT 
    jira_key,
    ticket_summary,
    status,
    assignee,
    TO_CHAR(updated_date, 'MM/DD/YYYY HH24:MI') as last_updated
FROM v_jira_tickets_dashboard
WHERE team_id = :APP_USER_TEAM_ID
ORDER BY updated_date DESC
FETCH FIRST 10 ROWS ONLY;
```

#### Region 3: Status Distribution Chart
**Type:** Chart (Pie)
**Source:**
```sql
SELECT 
    status as label,
    COUNT(*) as value
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
  AND is_active = 'Y'
GROUP BY status
ORDER BY COUNT(*) DESC;
```

### Buttons
- **View All Tickets** (Links to Page 2)
- **Add New Ticket** (Links to Page 3, Authorization: Can Edit)

---

## Page 2: Ticket List (Interactive Grid)

### Purpose
Main ticket management interface with inline editing

### Configuration

#### Interactive Grid
**Type:** Interactive Grid
**Source:**
```sql
SELECT 
    t.ticket_id,
    t.jira_key,
    t.ticket_summary,
    t.ticket_type,
    t.priority,
    t.status,
    t.assignee,
    t.reporter,
    t.sprint,
    t.story_points,
    t.week_number || '/' || t.week_year as week,
    t.due_date,
    t.team_id,
    TO_CHAR(t.updated_date, 'MM/DD/YYYY HH24:MI') as last_updated
FROM jira_tickets t
WHERE t.team_id = :APP_USER_TEAM_ID
  AND t.is_active = 'Y'
ORDER BY t.updated_date DESC;
```

#### Column Configuration
1. **TICKET_ID** - Hidden, Primary Key
2. **TEAM_ID** - Hidden
3. **JIRA_KEY** - Read Only, Link to Page 3
4. **TICKET_SUMMARY** - Text, Editable
5. **TICKET_TYPE** - Select List (LOV: LOV_TICKET_TYPE)
6. **PRIORITY** - Select List (LOV: LOV_PRIORITY)
7. **STATUS** - Select List (LOV: LOV_STATUS)
8. **ASSIGNEE** - Select List (LOV: LOV_ASSIGNEES)
9. **SPRINT** - Text
10. **STORY_POINTS** - Number
11. **WEEK** - Display Only
12. **DUE_DATE** - Date Picker
13. **LAST_UPDATED** - Display Only

#### Interactive Grid Attributes
- **Edit Mode:** Row
- **Lost Update Type:** Row Values
- **Editable:** Yes (with Authorization: Can Edit)
- **Add Row:** Yes (with Authorization: Can Edit)
- **Delete Row:** Yes (with Authorization: Can Manage)

#### Toolbar
- Search
- Actions Menu (Download, Filter, etc.)
- **Add Ticket** button (Authorization: Can Edit)

#### Filters (Search Bar)
- Quick filters for: Status, Priority, Assignee, Sprint

---

## Page 3: Ticket Details (Form)

### Purpose
Detailed view and edit form for individual tickets

### Form Configuration
**Type:** Form
**Table Name:** JIRA_TICKETS
**Primary Key:** TICKET_ID

#### Form Items
1. **P3_TICKET_ID** - Hidden
2. **P3_TEAM_ID** - Select List (LOV: LOV_TEAMS, Default: :APP_USER_TEAM_ID)
3. **P3_JIRA_KEY** - Text Field (Required)
4. **P3_JIRA_ID** - Text Field
5. **P3_TICKET_SUMMARY** - Text Field (Required)
6. **P3_TICKET_DESCRIPTION** - Rich Text Editor
7. **P3_TICKET_TYPE** - Radio Group (LOV: LOV_TICKET_TYPE)
8. **P3_PRIORITY** - Select List (LOV: LOV_PRIORITY)
9. **P3_STATUS** - Select List (LOV: LOV_STATUS, Required)
10. **P3_ASSIGNEE** - Select List (LOV: LOV_ASSIGNEES)
11. **P3_REPORTER** - Text Field
12. **P3_SPRINT** - Text Field
13. **P3_STORY_POINTS** - Number Field
14. **P3_ORIGINAL_ESTIMATE** - Number Field (Hours)
15. **P3_TIME_SPENT** - Number Field (Hours)
16. **P3_REMAINING_ESTIMATE** - Number Field (Hours)
17. **P3_DUE_DATE** - Date Picker
18. **P3_LABELS** - Text Field (Comma-separated)
19. **P3_COMPONENTS** - Text Field (Comma-separated)

#### Regions
1. **Basic Information** - Contains: Jira Key, Summary, Type, Priority, Status
2. **Assignment** - Contains: Assignee, Reporter, Sprint
3. **Effort Tracking** - Contains: Story Points, Time Estimates
4. **Additional Details** - Contains: Description, Labels, Components, Due Date

#### Processes
1. **Automatic Row Processing (DML)** - Standard form DML
2. **Update Week Information** - After Submit
   ```sql
   BEGIN
       UPDATE jira_tickets
       SET week_number = TO_NUMBER(TO_CHAR(SYSDATE, 'IW')),
           week_year = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'))
       WHERE ticket_id = :P3_TICKET_ID;
       
       jira_ticket_pkg.create_weekly_snapshot(:P3_TICKET_ID);
   END;
   ```

#### Buttons
- **Save** (Authorization: Can Edit)
- **Delete** (Authorization: Can Manage)
- **Cancel** (No authorization required)
- **Create** (Authorization: Can Edit)

#### Validations
1. **Check Edit Permission**
   ```sql
   RETURN jira_ticket_pkg.can_edit(:APP_USER_NAME, :P3_TEAM_ID);
   ```
2. **Unique Jira Key**
   ```sql
   SELECT 1
   FROM jira_tickets
   WHERE jira_key = :P3_JIRA_KEY
     AND ticket_id != :P3_TICKET_ID;
   ```

---

## Page 4: Weekly Status Report

### Purpose
View historical weekly snapshots and trends

### Regions

#### Region 1: Week Filter
**Type:** Static Content
**Items:**
- P4_WEEK_YEAR (Select List - Year)
- P4_WEEK_NUMBER (Select List - Week 1-52)
- Submit button to refresh report

#### Region 2: Weekly Summary
**Type:** Classic Report
**Source:**
```sql
SELECT 
    week_start_date,
    week_end_date,
    status,
    ticket_count,
    total_story_points,
    ROUND(total_time_spent, 2) as hours_spent
FROM v_weekly_status_report
WHERE week_number = :P4_WEEK_NUMBER
  AND week_year = :P4_WEEK_YEAR
  AND team_name = (SELECT team_name FROM teams WHERE team_id = :APP_USER_TEAM_ID)
ORDER BY status;
```

#### Region 3: Trend Chart
**Type:** Chart (Line)
**Source:**
```sql
SELECT 
    week_start_date as x_axis,
    status as series,
    ticket_count as value
FROM v_weekly_status_report
WHERE week_year = :P4_WEEK_YEAR
  AND team_name = (SELECT team_name FROM teams WHERE team_id = :APP_USER_TEAM_ID)
ORDER BY week_start_date, status;
```

#### Region 4: Ticket History Details
**Type:** Interactive Report
**Source:**
```sql
SELECT 
    h.jira_key,
    t.ticket_summary,
    h.status,
    h.assignee,
    h.sprint,
    h.story_points,
    h.snapshot_date
FROM jira_ticket_history h
JOIN jira_tickets t ON h.ticket_id = t.ticket_id
WHERE h.week_number = :P4_WEEK_NUMBER
  AND h.week_year = :P4_WEEK_YEAR
  AND t.team_id = :APP_USER_TEAM_ID
ORDER BY h.snapshot_date DESC;
```

---

## Page 5: Team Management

### Purpose
Manage teams and team members (Authorization: Can Manage)

### Authorization Scheme
Apply "Can Manage" to entire page

### Regions

#### Region 1: Teams
**Type:** Interactive Grid
**Source:**
```sql
SELECT 
    team_id,
    team_name,
    team_description,
    is_active,
    created_date
FROM teams
ORDER BY team_name;
```

#### Region 2: Team Members
**Type:** Interactive Grid
**Master Detail:** Based on Team selected in Region 1
**Source:**
```sql
SELECT 
    member_id,
    team_id,
    username,
    email,
    member_role,
    is_active,
    created_date
FROM team_members
WHERE team_id = :P5_TEAM_ID
ORDER BY member_role, username;
```

**Column Configuration:**
- USERNAME - Text
- EMAIL - Email
- MEMBER_ROLE - Select List (LOV: LOV_MEMBER_ROLE)
- IS_ACTIVE - Switch (Y/N)

---

## Page 6: User Administration

### Purpose
View and manage user access (Authorization: Is Admin)

### Authorization Scheme
Apply "Is Admin" to entire page

### Regions

#### Region 1: All Users Report
**Type:** Interactive Report
**Source:**
```sql
SELECT 
    tm.member_id,
    tm.username,
    tm.email,
    t.team_name,
    tm.member_role,
    tm.is_active,
    tm.created_date,
    tm.updated_date
FROM team_members tm
JOIN teams t ON tm.team_id = t.team_id
ORDER BY tm.username, t.team_name;
```

**Features:**
- Search across all columns
- Filter by role, team, active status
- Download options
- Link to edit (opens modal page)

---

## Page 7: Analytics & Charts

### Purpose
Visual analytics and reporting

### Regions

#### Region 1: Velocity Chart
**Type:** Chart (Bar)
**Source:**
```sql
SELECT 
    week_start_date as label,
    SUM(CASE WHEN status = 'Done' THEN story_points ELSE 0 END) as completed_points,
    SUM(story_points) as total_points
FROM jira_ticket_history
WHERE team_id = :APP_USER_TEAM_ID
  AND week_year = TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'))
GROUP BY week_start_date
ORDER BY week_start_date;
```

#### Region 2: Team Performance
**Type:** Chart (Pie)
**Source:**
```sql
SELECT 
    assignee as label,
    COUNT(*) as value
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
  AND status = 'Done'
  AND week_number = TO_NUMBER(TO_CHAR(SYSDATE, 'IW'))
  AND is_active = 'Y'
GROUP BY assignee
ORDER BY COUNT(*) DESC;
```

#### Region 3: Priority Distribution
**Type:** Chart (Donut)
**Source:**
```sql
SELECT 
    priority as label,
    COUNT(*) as value
FROM jira_tickets
WHERE team_id = :APP_USER_TEAM_ID
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

---

## Security Implementation Summary

### Role-Based Access Control

1. **VIEWER** - Can only view tickets
   - Read-only access to Pages 1, 2, 4, 7
   - No edit/delete buttons visible

2. **EDITOR** - Can view and edit tickets
   - Full access to Pages 1, 2, 3, 4, 7
   - Can create/edit tickets
   - Cannot delete or manage teams

3. **MANAGER** - Can manage tickets and view team members
   - All EDITOR permissions
   - Access to Page 5 (Team Management)
   - Can delete tickets

4. **ADMIN** - Full access
   - All permissions
   - Access to Page 6 (User Administration)
   - Can manage all aspects of the application

### Implementation Notes

1. Apply authorization schemes to:
   - Pages (for page-level access)
   - Buttons (for action-level access)
   - Regions (for content-level access)

2. Use dynamic actions to:
   - Refresh regions after updates
   - Show/hide elements based on role
   - Validate data before submission

3. Enable session state protection on all pages

4. Implement server-side validations in addition to client-side

---

## Additional Features to Consider

1. **Email Notifications** - Send alerts on ticket updates
2. **Jira Integration** - REST API integration to sync with Jira
3. **Export Functionality** - Export reports to Excel/PDF
4. **Custom Dashboards** - Per-user customizable dashboards
5. **Mobile Responsive** - Optimize for mobile devices
6. **Dark Mode** - Theme switcher
7. **Advanced Search** - Full-text search across tickets
8. **Comments/Activity Log** - Track all changes to tickets

---

## Testing Checklist

- [ ] Test all CRUD operations for each role
- [ ] Verify authorization schemes work correctly
- [ ] Test weekly snapshot creation
- [ ] Validate data integrity constraints
- [ ] Test pagination and sorting in reports
- [ ] Verify charts render correctly
- [ ] Test mobile responsiveness
- [ ] Check error handling and user feedback
- [ ] Test concurrent user updates
- [ ] Verify audit trail functionality

---

## Deployment Steps

1. Run database schema scripts in order (01, 02, 03)
2. Create APEX workspace (if not exists)
3. Create new application from scratch
4. Set up authentication scheme
5. Configure application items and processes
6. Create authorization schemes
7. Build pages as documented
8. Create navigation menu
9. Set up List of Values
10. Test thoroughly with different user roles
11. Deploy to production ADBS
12. Train end users
13. Monitor and iterate based on feedback
