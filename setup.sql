-- Setup
-- This script deletes everything in your database
\set QUIET true
SET client_min_messages TO NOTICE; -- Less talk please.
-- Use this instead of drop schema if running on the Chalmers Postgres server
-- DROP OWNED BY TDA357_XXX CASCADE;
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
\set QUIET false
-- Tables
CREATE TABLE Departments(
    name         TEXT PRIMARY KEY,
    abbriviation TEXT UNIQUE
);

CREATE TABLE Programs(
    name         TEXT PRIMARY KEY,
    abbriviation TEXT
);

--what departments hold what programs, assume many to many relationship
CREATE TABLE DepartmentPrograms( 
    departmentName TEXT REFERENCES Departments,
    programName    TEXT REFERENCES Programs
);

CREATE TABLE Branches(
    name        TEXT,
    program     TEXT REFERENCES Programs,

    PRIMARY KEY (name, program)
);

CREATE TABLE Students(
    idnr        CHAR(10) PRIMARY KEY CHECK (idnr SIMILAR TO '[0-9]{10}'),
    name        TEXT NOT NULL,
    login       TEXT NOT NULL UNIQUE,
    program     TEXT NOT NULL REFERENCES Programs,

    UNIQUE (idnr, program)
);

CREATE TABLE Courses(
    code        CHAR(6) PRIMARY KEY,
    name        TEXT NOT NULL,
    credits     FLOAT NOT NULL CHECK (credits >= 0), --got feedback to change allow 0 credits, but this was already allowed. No changes made
    department  TEXT REFERENCES Departments
);

CREATE TABLE Prerequisites(
    course      CHAR(6) REFERENCES Courses,
    required    CHAR(6) REFERENCES Courses,

    CHECK (course != required),
    PRIMARY KEY (course, required)
); 

CREATE TABLE LimitedCourses(
    code        CHAR(6) PRIMARY KEY REFERENCES Courses,
    capacity    INTEGER NOT NULL CHECK (capacity > 0)
);

CREATE TABLE MandatoryProgram(
    course      CHAR(6) REFERENCES Courses,
    program     TEXT REFERENCES Programs,

    PRIMARY KEY (course, program)
);

CREATE TABLE MandatoryBranch(
    course      CHAR(6) REFERENCES Courses,
    branch      TEXT,
    program     TEXT,

    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (branch, program) REFERENCES Branches
);

CREATE TABLE RecommendedBranch(
    course      CHAR(6) REFERENCES Courses,
    branch      TEXT,
    program     TEXT,

    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (branch, program) REFERENCES Branches
);

CREATE TABLE Taken(
    student     CHAR(10) REFERENCES Students,
    course      CHAR(6) REFERENCES Courses,
    grade       CHAR(1) NOT NULL CHECK (grade IN ('U', '3', '4', '5')),

    PRIMARY KEY (student, course) --shouldn't a student be able to retake a course?
);

CREATE TABLE StudentBranches(
    student     CHAR(10) PRIMARY KEY REFERENCES Students,
    branch      TEXT NOT NULL,
    program     TEXT NOT NULL,
    
    FOREIGN KEY (student, program) REFERENCES Students(idnr, program),
    FOREIGN KEY (branch, program) REFERENCES Branches
);

CREATE TABLE Classifications(
    name        TEXT PRIMARY KEY 
);

CREATE TABLE Classified(
    course          CHAR(6) REFERENCES Courses,
    classification  TEXT REFERENCES Classifications,

    PRIMARY KEY (course, classification)
);

CREATE TABLE Registered(
    student     CHAR(10) REFERENCES Students,
    course      CHAR(6) REFERENCES Courses,

    PRIMARY KEY (student, course)
);

CREATE TABLE WaitingList(
    student     CHAR(10) REFERENCES Students,
    course      CHAR(6) REFERENCES LimitedCourses,
    position    INTEGER NOT NULL CHECK (position > 0),

    UNIQUE (position, course),
    PRIMARY KEY (student, course)
);

-- Views
CREATE VIEW BasicInformation AS (
    SELECT idnr, name, login, Students.program, branch 
    FROM Students LEFT JOIN StudentBranches ON idnr = student
);

CREATE VIEW FinishedCourses AS (
    SELECT student, course, grade, Courses.credits
    FROM Taken JOIN Courses
    ON Taken.course = Courses.code    
);

CREATE VIEW PassedCourses AS (
    SELECT student, course, credits FROM FinishedCourses
    WHERE grade != 'U'
);

CREATE VIEW Registrations AS (
    SELECT student, course, 'waiting' AS status FROM WaitingList
    UNION
    SELECT student, course, 'registered' AS status FROM Registered
);

--students who haven't chosen a branch won't appear here, but cannot collect recommendedcredits and therefore not graduate
CREATE VIEW UnreadMandatory AS (
    SELECT idnr AS student, MandatoryProgram.course
    FROM Taken RIGHT JOIN
    (Students NATURAL JOIN Mandatoryprogram)
    ON (taken.student, taken.course) = (students.idnr, mandatoryprogram.course)
    WHERE grade IS NULL OR grade = 'U'
    UNION
    SELECT StudentBranches.student, MandatoryBranch.course
    FROM Taken RIGHT JOIN
    (StudentBranches NATURAL JOIN MandatoryBranch)
    ON (taken.student, taken.course) = (StudentBranches.student, MandatoryBranch.course)
    WHERE grade IS NULL OR grade = 'U'
);

-- can also be included in the with-statement of path to graduation instead of being a view
CREATE VIEW PassedClassifications AS (
    SELECT * FROM PassedCourses NATURAL JOIN Classified
);

CREATE VIEW PathToGraduation AS (
    WITH     
        student AS
            (SELECT idnr AS student FROM BasicInformation),
        totalCredits AS
            (SELECT student.student, COALESCE(SUM(credits), 0) AS totalCredits FROM student NATURAL LEFT JOIN PassedCourses GROUP BY student),
        mandatoryLeft AS
            (SELECT student.student, COALESCE(COUNT(course), 0) AS mandatoryLeft FROM student NATURAL LEFT JOIN UnreadMandatory GROUP BY student),
        seminarCourses AS
            (SELECT student, COUNT(course) AS seminarCourses FROM PassedClassifications WHERE classification = 'seminar' GROUP BY student),
        researchCredits AS
            (SELECT student, SUM(credits) AS researchCredits FROM PassedClassifications WHERE classification = 'research' GROUP BY student),
        mathCredits AS
            (SELECT student, SUM(credits) AS mathCredits FROM PassedClassifications WHERE classification = 'math' GROUP BY student),
        recommendedCredits AS
            (SELECT student.student, COALESCE(SUM(credits), 0) AS recommendedCredits
            FROM student NATURAL LEFT JOIN (PassedCourses NATURAL JOIN (StudentBranches NATURAL JOIN RecommendedBranch))
            GROUP BY student.student)
            
    SELECT student, totalCredits, mandatoryLeft, COALESCE(mathCredits, 0) AS mathCredits, COALESCE(researchCredits, 0) AS researchCredits, COALESCE(seminarCourses, 0) AS seminarCourses,
            COALESCE(mandatoryLeft = 0 AND recommendedCredits >= 10 AND mathCredits >= 20 AND researchCredits >= 10 AND seminarCourses >= 1, false) AS qualified

    FROM student NATURAL LEFT JOIN totalCredits NATURAL LEFT JOIN mandatoryLeft NATURAL LEFT JOIN mathCredits NATURAL LEFT JOIN researchCredits NATURAL LEFT JOIN seminarCourses NATURAL LEFT JOIN recommendedCredits
);

CREATE VIEW CourseQueuePositions AS (
    SELECT course, student, position AS place FROM WaitingList ORDER BY course ASC, position ASC
);

INSERT INTO Departments VALUES ('Dep1','D1');
INSERT INTO Departments VALUES ('Dep2','D2');
INSERT INTO Departments VALUES ('Dep3','D3');

INSERT INTO Programs VALUES ('Prog1','Dep1Dep2');
INSERT INTO Programs VALUES ('Prog2','Dep1Dep2');
INSERT INTO Programs VALUES ('Prog3','Dep3');

INSERT INTO DepartmentPrograms VALUES ('Dep1', 'Prog1');
INSERT INTO DepartmentPrograms VALUES ('Dep2', 'Prog1');
INSERT INTO DepartmentPrograms VALUES ('Dep1', 'Prog2');
INSERT INTO DepartmentPrograms VALUES ('Dep2', 'Prog2');
INSERT INTO DepartmentPrograms VALUES ('Dep3', 'Prog3');

INSERT INTO Branches VALUES ('B1','Prog1');
INSERT INTO Branches VALUES ('B2','Prog1');
INSERT INTO Branches VALUES ('B1','Prog2');

INSERT INTO Students VALUES ('1111111111','N1','ls1','Prog1');
INSERT INTO Students VALUES ('2222222222','N2','ls2','Prog1');
INSERT INTO Students VALUES ('3333333333','N3','ls3','Prog2');
INSERT INTO Students VALUES ('4444444444','N4','ls4','Prog1');
INSERT INTO Students VALUES ('5555555555','Nx','ls5','Prog2');
INSERT INTO Students VALUES ('6666666666','Nx','ls6','Prog2');
INSERT INTO Students VALUES ('7777777777','Nx','ls7','Prog2');

INSERT INTO Courses VALUES ('CCC111','C1',22.5,'Dep1');
INSERT INTO Courses VALUES ('CCC222','C2',20,'Dep1');
INSERT INTO Courses VALUES ('CCC333','C3',30,'Dep1');
INSERT INTO Courses VALUES ('CCC444','C4',60,'Dep1');
INSERT INTO Courses VALUES ('CCC555','C5',50,'Dep1');

INSERT INTO Prerequisites VALUES ('CCC111', 'CCC222');
INSERT INTO Prerequisites VALUES ('CCC222', 'CCC333');

INSERT INTO LimitedCourses VALUES ('CCC222',1);
INSERT INTO LimitedCourses VALUES ('CCC333',2);

INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333','math');
INSERT INTO Classified VALUES ('CCC444','math');
INSERT INTO Classified VALUES ('CCC444','research');
INSERT INTO Classified VALUES ('CCC444','seminar');

INSERT INTO StudentBranches VALUES ('2222222222','B1','Prog1');
INSERT INTO StudentBranches VALUES ('3333333333','B1','Prog2');
INSERT INTO StudentBranches VALUES ('4444444444','B1','Prog1');
INSERT INTO StudentBranches VALUES ('5555555555','B1','Prog2');

INSERT INTO MandatoryProgram VALUES ('CCC111','Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC444', 'B1', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');
INSERT INTO RecommendedBranch VALUES ('CCC333', 'B1', 'Prog2');

INSERT INTO Registered VALUES ('1111111111','CCC111');
INSERT INTO Registered VALUES ('1111111111','CCC222');
INSERT INTO Registered VALUES ('1111111111','CCC333');
INSERT INTO Registered VALUES ('2222222222','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC333');

INSERT INTO Taken VALUES('4444444444','CCC111','5');
INSERT INTO Taken VALUES('4444444444','CCC222','5');
INSERT INTO Taken VALUES('4444444444','CCC333','5');
INSERT INTO Taken VALUES('4444444444','CCC444','5');

INSERT INTO Taken VALUES('5555555555','CCC111','5');
INSERT INTO Taken VALUES('5555555555','CCC222','4');
INSERT INTO Taken VALUES('5555555555','CCC444','3');

INSERT INTO Taken VALUES('2222222222','CCC111','U');
INSERT INTO Taken VALUES('2222222222','CCC222','U');
INSERT INTO Taken VALUES('2222222222','CCC444','U');

INSERT INTO WaitingList VALUES('3333333333','CCC222', 1);
INSERT INTO WaitingList VALUES('3333333333','CCC333', 1);
INSERT INTO WaitingList VALUES('2222222222','CCC333', 2);


\ir triggers.sql
\ir tests.sql
