/* database restoration procedure
-- powershell
docker exec -it sql15001 sh -lc "mkdir -p /var/opt/mssql/backup"
docker cp "PATH" sql15001:/var/opt/mssql/backup/
--Dbeaver
RESTORE FILELISTONLY
FROM DISK = N'/var/opt/mssql/backup/QueensClassScheduleThisCurrentSemester.bak';

results- logical names, D- QC2019. L- QC2019_log

** RESTORE DATABASE [QueensClassScheduleThisCurrentSemester]
FROM DISK = N'/var/opt/mssql/backup/QueensClassScheduleThisCurrentSemester.bak'
WITH FILE = 1,
MOVE N'QC2019'
  TO N'/var/opt/mssql/data/QueensClassScheduleThisCurrentSemester.mdf',
MOVE N'QC2019_log'
  TO N'/var/opt/mssql/log/QueensClassScheduleThisCurrentSemester_log.ldf',
REPLACE,
STATS = 5;
*/



1️⃣ Schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Udt')
    EXEC ('CREATE SCHEMA Udt');

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Data')
    EXEC ('CREATE SCHEMA Data');

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Location')
    EXEC ('CREATE SCHEMA Location');

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Process')
    EXEC ('CREATE SCHEMA Process');

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DbSecurity')
    EXEC ('CREATE SCHEMA DbSecurity');







2️⃣ User Defined Data Types (Northwinds-Style, Self-Documenting)
CREATE TYPE Udt.SurrogateKeyInt     FROM INT NOT NULL;
CREATE TYPE Udt.DepartmentCode     FROM NVARCHAR(10) NOT NULL;
CREATE TYPE Udt.DepartmentName     FROM NVARCHAR(100) NOT NULL;
CREATE TYPE Udt.CourseCode         FROM NVARCHAR(20) NOT NULL;
CREATE TYPE Udt.CourseTitle        FROM NVARCHAR(200) NOT NULL;
CREATE TYPE Udt.FirstName          FROM NVARCHAR(50) NOT NULL;
CREATE TYPE Udt.LastName           FROM NVARCHAR(50) NOT NULL;
CREATE TYPE Udt.BuildingName       FROM NVARCHAR(100) NOT NULL;
CREATE TYPE Udt.RoomNumber         FROM NVARCHAR(20) NOT NULL;
CREATE TYPE Udt.ModeOfInstruction  FROM NVARCHAR(50) NOT NULL;
CREATE TYPE Udt.ClassSection       FROM NVARCHAR(10) NOT NULL;
CREATE TYPE Udt.DayPattern         FROM NVARCHAR(20) NOT NULL;
CREATE TYPE Udt.TimeString         FROM NVARCHAR(20) NOT NULL;
CREATE TYPE Udt.EnrollmentCount    FROM INT NULL;
CREATE TYPE Udt.DateAdded          FROM DATETIME2 NOT NULL;
CREATE TYPE Udt.DateOfLastUpdate   FROM DATETIME2 NOT NULL;

--3️⃣a 
User Authorization Table (Required)
CREATE TABLE DbSecurity.UserAuthorization
(
    UserAuthorizationKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    GroupMemberLastName  Udt.LastName,
    GroupMemberFirstName Udt.FirstName,
    GroupName            NVARCHAR(20) DEFAULT ('Group 2'),
    DateAdded            Udt.DateAdded DEFAULT SYSDATETIME()
);

INSERT INTO DbSecurity.UserAuthorization
VALUES ('Mahatab', 'Eusan', 'Group 2', SYSDATETIME());

--3b 
INSERT INTO DbSecurity.UserAuthorization
(
    GroupMemberLastName,
    GroupMemberFirstName,
    GroupName,
    DateAdded
)
VALUES
('Mahatab', 'Eusan',   'Group 2', SYSDATETIME()),
('Abrar',   'Azmain',  'Group 2', SYSDATETIME()),
('Rahman',      'Shiwlee', 'Group 2', SYSDATETIME()),
('Cherry',  'Zarrin',  'Group 2', SYSDATETIME()),
('Ding',    'Hali',    'Group 2', SYSDATETIME()),
('Wei',      'Haiyan',  'Group 2', SYSDATETIME());




--4️⃣ Core Normalized Tables (3NF)
Department
CREATE TABLE Data.Department
(
    DepartmentKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    DepartmentCode Udt.DepartmentCode UNIQUE,
    DepartmentName Udt.DepartmentName,
    UserAuthorizationKey INT,
    DateAdded Udt.DateAdded DEFAULT SYSDATETIME(),
    DateOfLastUpdate Udt.DateOfLastUpdate DEFAULT SYSDATETIME()
);

Instructor (Atomic + Persisted Full Name)
CREATE TABLE Data.Instructor
(
    InstructorKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    InstructorLastName  Udt.LastName,
    InstructorFirstName Udt.FirstName,
    InstructorFullName AS 
        (InstructorLastName + ', ' + InstructorFirstName) PERSISTED,
    UserAuthorizationKey INT,
    DateAdded Udt.DateAdded DEFAULT SYSDATETIME(),
    DateOfLastUpdate Udt.DateOfLastUpdate DEFAULT SYSDATETIME()
);

Instructor–Department (M:N)
CREATE TABLE Data.InstructorDepartment
(
    InstructorKey INT,
    DepartmentKey INT,
    UserAuthorizationKey INT,
    DateAdded Udt.DateAdded DEFAULT SYSDATETIME(),
    DateOfLastUpdate Udt.DateOfLastUpdate DEFAULT SYSDATETIME(),
    CONSTRAINT PK_InstructorDepartment PRIMARY KEY (InstructorKey, DepartmentKey),
    CONSTRAINT FK_ID_Instructor FOREIGN KEY (InstructorKey)
        REFERENCES Data.Instructor(InstructorKey),
    CONSTRAINT FK_ID_Department FOREIGN KEY (DepartmentKey)
        REFERENCES Data.Department(DepartmentKey)
);

Course (Credits + Business Rules)
CREATE TABLE Data.Course
(
    CourseKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    DepartmentKey INT,
    CourseCode Udt.CourseCode,
    CourseTitle Udt.CourseTitle,
    CreditHours INT CHECK (CreditHours BETWEEN 0 AND 6),
    UserAuthorizationKey INT,
    DateAdded Udt.DateAdded DEFAULT SYSDATETIME(),
    DateOfLastUpdate Udt.DateOfLastUpdate DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Course_Department FOREIGN KEY (DepartmentKey)
        REFERENCES Data.Department(DepartmentKey)
);

Mode of Instruction
CREATE TABLE Data.ModeOfInstruction
(
    ModeOfInstructionKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    ModeName Udt.ModeOfInstruction UNIQUE,
    UserAuthorizationKey INT,
    DateAdded Udt.DateAdded DEFAULT SYSDATETIME(),
    DateOfLastUpdate Udt.DateOfLastUpdate DEFAULT SYSDATETIME()
);

Building & Room
CREATE TABLE Location.BuildingLocation
(
    BuildingLocationKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    BuildingName Udt.BuildingName UNIQUE,
    UserAuthorizationKey INT,
    DateAdded Udt.DateAdded DEFAULT SYSDATETIME()
);

CREATE TABLE Location.RoomLocation
(
    RoomLocationKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    BuildingLocationKey INT,
    RoomNumber Udt.RoomNumber,
    UserAuthorizationKey INT,
    DateAdded Udt.DateAdded DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Room_Building FOREIGN KEY (BuildingLocationKey)
        REFERENCES Location.BuildingLocation(BuildingLocationKey)
);

Class (Fact Table)
CREATE TABLE Data.Class
(
    ClassKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    CourseKey INT,
    InstructorKey INT,
    RoomLocationKey INT,
    ModeOfInstructionKey INT,
    Section Udt.ClassSection,
    Days Udt.DayPattern,
    ClassTime Udt.TimeString,
    Enrollment Udt.EnrollmentCount CHECK (Enrollment >= 0),
    Capacity Udt.EnrollmentCount,
    UserAuthorizationKey INT,
    DateAdded Udt.DateAdded DEFAULT SYSDATETIME(),
    DateOfLastUpdate Udt.DateOfLastUpdate DEFAULT SYSDATETIME(),
    FOREIGN KEY (CourseKey) REFERENCES Data.Course(CourseKey),
    FOREIGN KEY (InstructorKey) REFERENCES Data.Instructor(InstructorKey),
    FOREIGN KEY (RoomLocationKey) REFERENCES Location.RoomLocation(RoomLocationKey),
    FOREIGN KEY (ModeOfInstructionKey) REFERENCES Data.ModeOfInstruction(ModeOfInstructionKey)
);

5️⃣ WorkflowSteps (MATCHES SPEC)
CREATE TABLE Process.WorkflowSteps
(
    WorkFlowStepKey Udt.SurrogateKeyInt IDENTITY PRIMARY KEY,
    WorkFlowStepDescription NVARCHAR(100),
    WorkFlowStepTableRowCount INT DEFAULT 0,
    StartingDateTime DATETIME2 DEFAULT SYSDATETIME(),
    EndingDateTime DATETIME2 DEFAULT SYSDATETIME(),
    ClassTime CHAR(5) DEFAULT ('09:15'),
    UserAuthorizationKey INT
);

6️⃣ Workflow Stored Procedures (Spec-Aligned)
CREATE OR ALTER PROCEDURE Process.usp_TrackWorkFlow
(
    @StartTime DATETIME2,
    @WorkFlowDescription NVARCHAR(100),
    @WorkFlowStepTableRowCount INT,
    @UserAuthorizationKey INT
)
AS
BEGIN
    INSERT INTO Process.WorkflowSteps
    VALUES
    (
        @WorkFlowDescription,
        @WorkFlowStepTableRowCount,
        @StartTime,
        SYSDATETIME(),
        '09:15',
        @UserAuthorizationKey
    );
END;

CREATE OR ALTER PROCEDURE Process.usp_ShowWorkflowSteps
AS
BEGIN
    SELECT * FROM Process.WorkflowSteps ORDER BY WorkFlowStepKey;
END;

--LEts Insert  Data into some tables
------------------------------------------------------------
-- 1) User Authorization
------------------------------------------------------------
INSERT INTO DbSecurity.UserAuthorization
(GroupMemberLastName, GroupMemberFirstName, GroupName)
VALUES
('User', 'System', 'Default Group');
GO

------------------------------------------------------------
-- 2) Departments

INSERT INTO Data.Department
(DepartmentCode, DepartmentName, UserAuthorizationKey)
VALUES
('CSCI', 'Computer Science', 1),
('MATH', 'Mathematics', 1),
('ENG',  'English', 1);
GO

-- 3) Instructors

INSERT INTO Data.Instructor
(InstructorLastName, InstructorFirstName, UserAuthorizationKey)
VALUES
('Doe', 'Alex', 1),
('Taylor', 'Jordan', 1),
('Morgan', 'Casey', 1);
GO

-- 4) Instructor–Department Bridge

INSERT INTO Data.InstructorDepartment
(InstructorKey, DepartmentKey, UserAuthorizationKey)
VALUES
(1, 1, 1), -- Alex Doe → CSCI
(2, 2, 1), -- Jordan Taylor → MATH
(3, 3, 1); -- Casey Morgan → ENG
GO

-- 5) Courses

INSERT INTO Data.Course
(DepartmentKey, CourseCode, CourseTitle, CreditHours, UserAuthorizationKey)
VALUES
(1, 'CSCI 316', 'Programming Languages', 3, 1),
(1, 'CSCI 320', 'Data Structures', 3, 1),
(2, 'MATH 241', 'Linear Algebra', 4, 1),
(3, 'ENG 110',  'College Writing', 3, 1);
GO


-- 6) Modes of Instruction

INSERT INTO Data.ModeOfInstruction
(ModeName, UserAuthorizationKey)
VALUES
('In Person', 1),
('Online', 1),
('Hybrid', 1);
GO
-- 7) Buildings
INSERT INTO Location.BuildingLocation
(BuildingName, UserAuthorizationKey)
VALUES
('Science Hall', 1),
('Math Hall', 1),
('Humanities Hall', 1);
GO
-- 8) Rooms
INSERT INTO Location.RoomLocation
(BuildingLocationKey, RoomNumber, UserAuthorizationKey)
VALUES
(1, 'SH-201', 1),
(1, 'SH-305', 1),
(2, 'MH-110', 1),
(3, 'HH-220', 1);
GO

-- 9) Classes (Fact Table)
INSERT INTO Data.Class
(
    CourseKey,
    InstructorKey,
    RoomLocationKey,
    ModeOfInstructionKey,
    Section,
    Days,
    ClassTime,
    Enrollment,
    Capacity,
    UserAuthorizationKey
)
VALUES
(1, 1, 1, 1, 'A', 'MW',  '09:15-10:30', 28, 35, 1),
(2, 2, 2, 3, 'B', 'TR',  '11:00-12:15', 22, 30, 1),
(3, 2, 3, 2, 'C', 'MWF', '13:00-13:50', 35, 40, 1),
(4, 3, 4, 1, 'D', 'TR',  '14:30-15:45', 18, 25, 1);
GO

-----------------------------------------------------

