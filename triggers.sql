-- Triggers
CREATE OR REPLACE FUNCTION registerStudent() RETURNS TRIGGER AS $registerStudent$
    DECLARE
        missing         TEXT;
        fullCourse      BOOLEAN;
        cap             Integer;
        reg             Integer;
        --pos             Integer;
        
BEGIN     
    -- Check if student is already registered in course
    IF EXISTS (SELECT 1 FROM Registered WHERE Registered.student=NEW.student AND Registered.course=NEW.course) THEN
        RAISE EXCEPTION 'Student % is already registered in course %.', NEW.student, NEW.course;
    END IF;

    -- Check if student is on waiting list for course
    IF EXISTS (SELECT 1 FROM WaitingList WHERE WaitingList.student=NEW.student AND WaitingList.course=NEW.course) THEN
        RAISE EXCEPTION 'Student % is already on waitinglist for course %.', NEW.student, NEW.course;
    END IF; 

    -- Check if the student has completed the prerequired courses
    WITH
        requiredCourses AS
            (SELECT required FROM Prerequisites WHERE Prerequisites.course = NEW.course),
        passed AS
            (SELECT course FROM PassedCourses WHERE PassedCourses.student = NEW.student)        
    SELECT required INTO missing FROM requiredCourses WHERE NOT EXISTS (SELECT FROM passed WHERE course = required);
    
    IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'All required courses are not passed. Missing courses: %', missing;
    END IF;
        
    -- Check if the course is full
    fullCourse := False;
    IF EXISTS (SELECT 1 FROM LimitedCourses WHERE code = NEW.course) THEN
        cap := (SELECT capacity FROM LimitedCourses WHERE code = NEW.course);
        reg := (SELECT count(*) FROM Registrations WHERE (Registrations.course = NEW.course AND status = 'registered'));
        IF reg >= cap THEN
            fullCourse := True;
            RAISE NOTICE 'Course % is full.', NEW.course;
        END IF;
    END IF;
    
    IF fullCourse THEN   
        --pos := (SELECT count(position)+1 FROM WaitingList WHERE course = NEW.course);
        INSERT INTO WaitingList VALUES (NEW.student, NEW.course);
        RAISE NOTICE 'Put on waitinglist for course %.', NEW.course;
    ELSE
        INSERT INTO Registered VALUES (NEW.student, NEW.course);
        RAISE NOTICE 'Registered for course %.', NEW.course;
    END IF;

    RETURN NEW;
END;
$registerStudent$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION unregisterStudent() RETURNS TRIGGER AS $unregisterStudent$
    DECLARE
        studentExists   BOOLEAN;
        courseExists    BOOLEAN;
        isWaiting       BOOLEAN;
        isLimited       BOOLEAN;
        isRegistered    BOOLEAN;
        isWaitingEmpty  BOOLEAN;
        newStudent      CHAR(10);
BEGIN
    studentExists := EXISTS (SELECT 1 FROM Students WHERE OLD.student = idnr);
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
        RAISE NOTICE 'Student % removed from waiting list for course %.', OLD.student, OLD.course;
    ELSIF isRegistered THEN
        DELETE FROM Registered WHERE (Registered.student = OLD.student AND Registered.Course = OLD.course);
        RAISE NOTICE 'Student % removed from course %.', OLD.student, OLD.course;        
    END IF;    

    -- Check if limited course has empty waiting list
    isWaitingEmpty := (SELECT student FROM CourseQueuePositions WHERE place = 1 AND CourseQueuePositions.course = OLD.course) IS NULL;

    -- If unregistering from a limited course, add the next person on the waiting list to the course.
    IF isRegistered AND isLimited AND NOT isWaitingEmpty THEN
        newStudent := (SELECT student FROM CourseQueuePositions WHERE place = 1 AND CourseQueuePositions.course = OLD.course);
        INSERT INTO Registered VALUES(newStudent, OLD.course);
        DELETE FROM WaitingList WHERE (WaitingList.student = newStudent AND WaitingList.Course = OLD.course);
        RAISE NOTICE 'Student % added to course % from waiting list.', newStudent, OLD.course;  
    END IF;

    RETURN NULL;
END;
$unregisterStudent$ LANGUAGE plpgsql;

CREATE TRIGGER unregisterStudent INSTEAD OF DELETE ON Registrations 
            FOR EACH ROW EXECUTE FUNCTION unregisterStudent();

CREATE TRIGGER registerStudent INSTEAD OF INSERT ON Registrations 
            FOR EACH ROW EXECUTE FUNCTION registerStudent();
