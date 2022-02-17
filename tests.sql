-- TEST #1: Register for an unlimited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('XXXXXXXXXX', 'CCCXXX'); 

-- TEST #2: Register an already registered student.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('XXXXXXXXXX', 'CCCXXX'); 

-- TEST #3: Unregister from an unlimited course. 
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = 'XXXXXXXXXX' AND course = 'CCCXXX';
