-- TEST #1: register to a course where the student is already registered
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('1111111111','CCC111');

-- TEST #2: register to a course where the student is already on the waiting list
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('3333333333','CCC222');

-- TEST #3: register to a course where the student does not meet the prerequisites
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('7777777777','CCC222');

-- TEST #4: registered to an unlimited course;
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('0101010101','TEEEST');

-- TEST #5: registered to a limited course;
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('0101010101','TESTLI');

-- TEST #6: waiting for a limited course;
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('3333333333','TESTLI');

-- TEST #7: remove from a waiting list (with additional students in it)
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '3333333333' AND course = 'CCC333';

-- TEST #8: unregistered from an unlimited course;
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '1111111111' AND course = 'CCC111';

-- TEST #9: unregistered from a limited course without a waiting list;
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '5555555555' AND course = 'CCC666';

-- TEST #10: unregistered from a limited course with a waiting list, when the student is registered;
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '5555555555' AND course = 'CCC333';

-- TEST #11: unregistered from an overfull course with a waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '8888888888' AND course = 'CCC222';

-- TEST #12: register to already passed course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('4444444444', 'CCC111');