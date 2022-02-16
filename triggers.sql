-- Triggers
CREATE FUNCTION registerStudent() RETURNS TRIGGER AS $registerStudent$
    DECLARE
        missing         TEXT;
        fullCourse      BOOLEAN;
        cap             Integer;
        reg             Integer;
        
BEGIN     
    -- Check if student is already registered in course
    IF EXISTS (SELECT 1 FROM Registered WHERE Registered.student=NEW.student AND Registered.course=NEW.course) THEN
        RAISE EXCEPTION 'Student % is already registered in course %.', NEW.student, NEW.course;
    END IF;

    -- Check if the student has completed the prerequired courses
    WITH
        requiredCourses AS
            (SELECT required FROM Prerequisites WHERE Prerequisites.course = NEW.course),
        passed AS
            (SELECT course FROM PassedCourses WHERE PassedCourses.student = NEW.student)        
    SELECT required INTO missing FROM requiredCourses WHERE NOT EXISTS (SELECT FROM passed WHERE course = required);
    
    IF EXISTS missing THEN
        RAISE EXCEPTION 'All required courses are not passed. Missing courses: %', missing;
    END IF;
    
    fullCourse := False;
    -- Check if the course is full
    IF EXISTS (SELECT 1 FROM LimitedCourses WHERE code = NEW.course) THEN
        cap := (SELECT capacity FROM LimitedCourses WHERE code = NEW.course);
        reg := (SELECT count(*) FROM Registrations WHERE (Registrations.course = NEW.course AND status = 'registered'));
        IF reg >= cap THEN
            fullCourse := True;
            RAISE NOTICE 'Course % is full.', NEW.course;
        END IF;
    END IF;
    
    IF fullCourse THEN    
        INSERT INTO WaitingList VALUES (NEW.student, NEW.course);
        RAISE NOTICE 'Put on waitinglist for course %.', NEW.course;
    ELSE
        INSERT INTO Registered VALUES (NEW.student, NEW.course);
        RAISE NOTICE 'Registered for course %.', NEW.course;
    END IF;
END;
$registerStudent$ LANGUAGE plpgsql;

/*
Registered(student, course)
*/
CREATE FUNCTION unregisterStudent() RETURNS TRIGGER 
AS $unregisterStudent$
DECLARE
    studentExists   BOOLEAN;
    courseExists    BOOLEAN;
    isWaiting       BOOLEAN;
    isLimited       BOOLEAN;
    isRegistered    BOOLEAN;
    newStudent      CHAR(10);
BEGIN
    studentExists := EXISTS (SELECT 1 FROM Students WHERE OLD.student = studentIdnr);
    courseExists := EXISTS (SELECT 1 FROM Courses WHERE OLD.course = code);

    IF NOT courseExists AND NOT studentExists THEN
        RAISE EXCEPTION 'Student % and course % does not exist.', OLD.student, OLD.course;
    END IF;

    IF NOT studentExists THEN
        RAISE EXCEPTION 'Student % does not exist.', OLD.student;
    END IF;

    IF NOT courseExists THEN
        RAISE EXCEPTION 'Course % does not exist.', OLD.course;
    END IF;

    -- Check if the student is on the waiting list.
    isWaiting := EXISTS (SELECT 1 FROM Registrations WHERE Registrations.student = OLD.student AND status = 'waiting');
    
    -- Check if the course is limited.
    isLimited := EXISTS (SELECT 1 FROM LimitedCourses WHERE LimitedCourses.code = OLD.course);
    
    -- Check if the student is registered in the course.
    isRegistered := EXISTS (SELECT 1 FROM Registrations WHERE Registrations.student = OLD.student AND status = 'registered');
    
    IF isWaiting THEN
        DELETE FROM WaitingList WHERE (WaitingList.student = OLD.student AND WaitingList.Course = OLD.course);
    END IF;

    IF isRegistered THEN
        DELETE FROM Registered WHERE (Registered.student = OLD.student AND Registered.Course = OLD.course);
    END IF;    

    -- If unregistering from a limited course, add the next person on the waiting list to the course.
    IF isRegistered AND isLimited THEN
        newStudent := (SELECT student FROM CourseQueuePositions WHERE place = 1 AND CourseQueuePositions.course = course);
        INSERT INTO Registered VALUES(newStudent, OLD.course);
        DELETE FROM WaitingList WHERE (WaitingList.student = newStudent AND WaitingList.Course = OLD.course);
    END IF;
END;
$unregisterStudent$ LANGUAGE plpgsql;



CREATE TRIGGER unregisterStudent INSTEAD OF DELETE ON Registrations 
            FOR EACH ROW EXECUTE FUNCTION unregisterStudent();


CREATE TRIGGER registerStudent INSTEAD OF INSERT ON Registrations 
            FOR EACH STATEMENT EXECUTE FUNCTION registerStudent();


/*
ERROR:  cannot insert into view "registrations"
DETAIL:  Views containing UNION, INTERSECT, or EXCEPT are not automatically updatable.
HINT:  To enable inserting into the view, provide an INSTEAD OF INSERT trigger or an unconditional ON INSERT DO INSTEAD rule.


ERROR:  trigger functions cannot have declared arguments
HINT:  The arguments of the trigger can be accessed through TG_NARGS and TG_ARGV instead.
CONTEXT:  compilation of PL/pgSQL function "unregisterstudent" near line 1
*/

SELECT EXISTS(SELECT 'CCC222' FROM LimitedCourses WHERE LimitedCourses.code = 'CCC222')