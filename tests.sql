-- TEST #1: Register for an unlimited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('XXXXXXXXXX', 'CCCXXX'); 

-- TEST #2: Register an already registered student.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('XXXXXXXXXX', 'CCCXXX'); 

-- TEST #3: Unregister from an unlimited course. 
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = 'XXXXXXXXXX' AND course = 'CCCXXX';

---- Fail ----
-- TEST #1: register to a course where the student is already registered
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('QQQQQQQQQQ', '')

-- TEST #2: register to a course where the student is already on the waiting list
-- EXPECTED OUTCOME: Fail

-- TEST #3: register to a course where the student does not meet the prerequisites
-- EXPECTED OUTCOME: Fail

-- TEST #4: unregister from a course that the student is not participating in
-- EXPECTED OUTCOME: Fail

-- TEST #5: unregister from a course where the student and course does not exist
-- EXPECTED OUTCOME: Fail

-- TEST #6: unregister from a course where the student does not exist
-- EXPECTED OUTCOME: Fail

-- TEST #7: unregister from a course where the course does not exist
-- EXPECTED OUTCOME: Fail

---- Pass ----
-- TEST #8: registered to an unlimited course;
-- EXPECTED OUTCOME: Pass

-- TEST #9: registered to a limited course;
-- EXPECTED OUTCOME: Pass

-- TEST #10: waiting for a limited course;
-- EXPECTED OUTCOME: Pass

-- TEST #11: removed from a waiting list (with additional students in it)
-- EXPECTED OUTCOME: Pass

-- TEST #12: unregistered from an unlimited course;
-- EXPECTED OUTCOME: Pass

-- TEST #13: unregistered from a limited course without a waiting list;
-- EXPECTED OUTCOME: Pass

-- TEST #14: unregistered from a limited course with a waiting list, when the student is registered;
-- EXPECTED OUTCOME: Pass

-- TEST #15: unregistered from a limited course with a waiting list, when the student is in the middle of the waiting list;
-- EXPECTED OUTCOME: Pass

-- TEST #16: unregistered from an overfull course with a waiting list.
-- EXPECTED OUTCOME: Pass
