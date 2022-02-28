CREATE VIEW CourseQueuePositions AS (
    SELECT course, student, ROW_NUMBER() OVER(PARTITION BY course ORDER BY position ASC) AS place FROM WaitingList
);

-- Triggers
CREATE FUNCTION registerStudent() 
    RETURNS TRIGGER 
AS $$
DECLARE
    missing         RECORD;
    missed          TEXT;
    fullCourse      BOOLEAN;
    cap             Integer;
    reg             Integer;
BEGIN
    -- Check if student exists. Not really neccessary to check as both waitinglist and registrations has a foreign key to students table
    IF NOT EXISTS (SELECT 1 FROM Students WHERE NEW.student = idnr) THEN
        RAISE EXCEPTION 'Student % does not exist.', NEW.student;
    END IF;

    -- Check if course exists. Same as above
    IF NOT EXISTS (SELECT 1 FROM Courses WHERE NEW.course = code) THEN
        RAISE EXCEPTION 'Course % does not exist.', NEW.course;
    END IF;

    -- Check if student is already registered in course. Same as above. Primary key checks this
    IF EXISTS (SELECT 1 FROM Registered WHERE Registered.student=NEW.student AND Registered.course=NEW.course) THEN
        RAISE EXCEPTION 'Student % is already registered in course %.', NEW.student, NEW.course;
    END IF;

    -- Check if student is on waiting list for course. Same as above. Primary key checks this
    IF EXISTS (SELECT 1 FROM WaitingList WHERE WaitingList.student=NEW.student AND WaitingList.course=NEW.course) THEN
        RAISE EXCEPTION 'Student % is already on waitinglist for course %.', NEW.student, NEW.course;
    END IF; 

    -- Check if the student has completed the prerequired courses
    -- Creating a temp table for this is probably not the best solution, but found no other way to print multiple missing courses
    CREATE TEMP TABLE MissingCourses(
        missCourses  TEXT
    );

    WITH
        requiredCourses AS
            (SELECT required FROM Prerequisites WHERE Prerequisites.course = NEW.course),
        passed AS
            (SELECT course FROM PassedCourses WHERE PassedCourses.student = NEW.student)     
    INSERT INTO MissingCourses SELECT required FROM requiredCourses EXCEPT SELECT course FROM passed;
        
    IF EXISTS (SELECT 1 FROM MissingCourses) THEN        
        FOR missing IN SELECT * FROM MissingCourses LOOP
            missed := CONCAT(missed, missing.missCourses, ' ');
        END LOOP;        
        DROP TABLE MissingCourses;
        RAISE EXCEPTION 'Student % has not passed all required courses for course %. Missing: %', NEW.student, NEW.course, missed;
    END IF;
    
    DROP TABLE MissingCourses;
        
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
        INSERT INTO WaitingList VALUES (NEW.student, NEW.course);
        RAISE NOTICE 'Student % put on waitinglist for course %.', NEW.student, NEW.course;
    ELSE
        INSERT INTO Registered VALUES (NEW.student, NEW.course);
        RAISE NOTICE 'Student % registered for course %.', NEW.student, NEW.course;
    END IF;

    RETURN NEW;

END; 
$$ LANGUAGE plpgsql; 

CREATE FUNCTION unregisterStudent() 
RETURNS TRIGGER 
AS $$
DECLARE
    isWaiting       BOOLEAN;
    isLimited       BOOLEAN;
    isRegistered    BOOLEAN;
    isWaitingEmpty  BOOLEAN;
    newStudent      CHAR(10);
BEGIN

    -- Check if the student is on the waiting list.
    isWaiting := EXISTS (SELECT 1 FROM Registrations WHERE Registrations.student = OLD.student AND Registrations.course = OLD.course AND status = 'waiting');
    -- Check if the course is limited.
    isLimited := EXISTS (SELECT 1 FROM LimitedCourses WHERE LimitedCourses.code = OLD.course);
    -- Check if the student is registered in the course.
    isRegistered := EXISTS (SELECT 1 FROM Registrations WHERE Registrations.student = OLD.student AND Registrations.course = OLD.course AND status = 'registered');
    
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

    RETURN OLD;
END; 
$$ LANGUAGE plpgsql;



CREATE TRIGGER registerStudent INSTEAD OF INSERT ON Registrations 
    FOR EACH ROW EXECUTE FUNCTION registerStudent();

CREATE TRIGGER unregisterStudent INSTEAD OF DELETE ON Registrations
    FOR EACH ROW EXECUTE FUNCTION unregisterStudent();