---- Fail ----
-- TEST #1: register to a course where the student is already registered
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('1111111111','CCC111');

-- TEST #2: register to a course where the student is already on the waiting list
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('3333333333','CCC222');

-- TEST #3: register to a course where the student does not meet the prerequisites
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222','CCC333');

-- TEST #4: unregister from a course that the student is not participating in
-- EXPECTED OUTCOME: Fail
DELETE FROM Registrations WHERE student = '1111111111' AND course = 'CCC333';

-- TEST #5: unregister from a course where the student and course does not exist
-- EXPECTED OUTCOME: Fail
DELETE FROM Registrations WHERE student = 'QQQQQQQQQQ' AND course = 'CCCQQQ';

-- TEST #6: unregister from a course where the student does not exist
-- EXPECTED OUTCOME: Fail
DELETE FROM Registrations WHERE student = 'QQQQQQQQQQ' AND course = 'CCC333';

-- TEST #7: unregister from a course where the course does not exist
-- EXPECTED OUTCOME: Fail
DELETE FROM Registrations WHERE student = '1111111111' AND course = 'CCCQQQ';

---- Pass ----
-- TEST #8: registered to an unlimited course;
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('777777777','CCC111');

-- TEST #9: registered to a limited course;
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('777777777','CCC222');

-- TEST #10: waiting for a limited course;
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('333333333','CCC222');

-- TEST #11: removed from a waiting list (with additional students in it)
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '333333333' AND course = 'CCC222';

-- TEST #12: unregistered from an unlimited course;
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '111111111' AND course = 'CCC111';

-- TEST #13: unregistered from a limited course without a waiting list;
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '5555555555' AND course = 'CCC666';

-- TEST #14: unregistered from a limited course with a waiting list, when the student is registered;
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '5555555555' AND course = 'CCC333';

-- TEST #15: unregistered from a limited course with a waiting list, when the student is in the middle of the waiting list;
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '2222222222' AND course = 'CCC333';

-- TEST #16: unregistered from an overfull course with a waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '8888888888' AND course = 'CCC222';
