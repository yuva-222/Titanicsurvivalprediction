create database titanic_survival;
use titanic_survival;
create table Passengers(
			PassengerId INT PRIMARY KEY,
			Survived INT,
			Pclass INT,
			Name_ VARCHAR(255),
			Sex VARCHAR(10),
			Age FLOAT,
			SibSp INT,
			Parch INT,
			Ticket VARCHAR(255),
			Fare FLOAT,
			Cabin VARCHAR(255),
			Embarked VARCHAR(10));
select * from Passengers;

-- create a table for genders 
CREATE TABLE Genders (
    GenderId INT PRIMARY KEY,
    Gender VARCHAR(10)
);

-- Create a table for ports of embarkation
CREATE TABLE EmbarkationPorts (
    PortId INT PRIMARY KEY,
    PortName VARCHAR(20)
);

-- Create a table for passenger relationships (Siblings/Spouses and Parents/Children)
CREATE TABLE Relationships (
    RelationshipId INT PRIMARY KEY,
    RelationshipType VARCHAR(20)
);

-- Populate the Genders table
INSERT INTO Genders (GenderId, Gender)
VALUES
    (1, 'male'),
    (2, 'female');
    
-- Populate the EmbarkationPorts table
INSERT INTO EmbarkationPorts (PortId, PortName)
VALUES
    (1, 'C'),
    (2, 'Q'),
    (3, 'S');
    
-- Populate the Relationships table
INSERT INTO Relationships (RelationshipId, RelationshipType)
VALUES
    (1, 'SibSp'),
    (2, 'Parch');
    
-- Create a junction table to represent passenger relationships
CREATE TABLE PassengerRelationships (
    PassengerId INT,
    RelationshipId INT,
    Quantity INT,
    PRIMARY KEY (PassengerId, RelationshipId),
    FOREIGN KEY (PassengerId) REFERENCES Passengers(PassengerId),
    FOREIGN KEY (RelationshipId) REFERENCES Relationships(RelationshipId)
);

-- Create the final structure combining all relationships
CREATE TABLE PassengerData (
    PassengerId INT PRIMARY KEY,
    Survived INT,
    Pclass INT,
    Name_ VARCHAR(255),
    GenderId INT,
    Age FLOAT,
    Ticket VARCHAR(255),
    Fare FLOAT,
    Cabin VARCHAR(255),
    PortId INT,
    FOREIGN KEY (GenderId) REFERENCES Genders(GenderId),
    FOREIGN KEY (PortId) REFERENCES EmbarkationPorts(PortId)
);

-- Identify missing values in the Passengers table
SELECT COUNT(*) AS TotalRows,
       SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS MissingAge,
       SUM(CASE WHEN Cabin IS NULL THEN 1 ELSE 0 END) AS MissingCabin,
       SUM(CASE WHEN Embarked IS NULL THEN 1 ELSE 0 END) AS MissingEmbarked,
	   SUM(CASE WHEN Fare IS NULL THEN 1 ELSE 0 END) AS MissingFare
FROM Passengers;

-- Clean the data by dropping the Cabin column
ALTER TABLE Passengers DROP COLUMN Cabin;

-- Create a column 'IsChild' to identify passengers who are children (age <= 12)
ALTER TABLE Passengers ADD COLUMN IsChild INT;
UPDATE Passengers
SET IsChild = CASE WHEN Age <= 12 THEN 1 ELSE 0 END;

-- Create a column 'FamilySize' to represent the total family size of each passenger
ALTER TABLE Passengers ADD COLUMN FamilySize INT;
UPDATE Passengers
SET FamilySize = SibSp + Parch + 1;

-- Create a column 'FarePerPerson' to calculate the fare per person
ALTER TABLE Passengers ADD COLUMN FarePerPerson FLOAT;
UPDATE Passengers
SET FarePerPerson = Fare / FamilySize;

-- Create a column 'EmbarkedPort' to map port names to their IDs
ALTER TABLE Passengers ADD COLUMN EmbarkedPort INT;
UPDATE Passengers
SET EmbarkedPort = CASE
    WHEN Embarked = 'C' THEN 1
    WHEN Embarked = 'Q' THEN 2
    WHEN Embarked = 'S' THEN 3
    ELSE NULL
END;

-- Drop the original Embarked column
ALTER TABLE Passengers DROP COLUMN Embarked;

-- Join the PassengerData table to include gender and embarkation information
CREATE TABLE FinalPassengerData AS
SELECT p.PassengerId, p.Survived, p.Pclass, p.Name_, g.GenderId, p.Age, p.SibSp,
       p.Parch, p.Ticket, p.Fare, p.EmbarkedPort
FROM Passengers p
JOIN Genders g ON p.Sex = g.Gender;

-- Identify average survival rate based on gender
SELECT g.Gender, AVG(fpd.Survived) AS AvgSurvivalRate
FROM FinalPassengerData fpd
JOIN Genders g ON fpd.GenderId = g.GenderId
GROUP BY g.Gender;


-- Identify average survival rate based on passenger class
SELECT Pclass, AVG(Survived) AS AvgSurvivalRate
FROM FinalPassengerData
GROUP BY Pclass;

-- Identify average survival rate based on family size
SELECT FamilySize, AVG(Survived) AS AvgSurvivalRate
FROM Passengers
GROUP BY FamilySize;

-- Identify average survival rate based on whether the passenger is a child
SELECT IsChild, AVG(Survived) AS AvgSurvivalRate
FROM Passengers
GROUP BY IsChild;

-- Identify average survival rate based on embarkation port
SELECT EmbarkedPort, AVG(Survived) AS AvgSurvivalRate
FROM Passengers
GROUP BY EmbarkedPort;


