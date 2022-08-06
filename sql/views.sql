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