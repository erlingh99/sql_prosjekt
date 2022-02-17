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

    UNIQUE (position, courseCode),
    PRIMARY KEY (student, course)
);