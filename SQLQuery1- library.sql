
--Question 1


--Create the database
CREATE DATABASE Library;


--Create Members Table
CREATE TABLE Members (
    MemberID int IDENTITY(1,1) PRIMARY KEY,
    FullName varchar(100) NOT NULL,
    Address varchar(200) NOT NULL,
    DateOfBirth date NOT NULL,
    Username varchar(50) NOT NULL,
    Password varchar(50) NOT NULL,
    Email varchar(100),
    Telephone varchar(20),    
);

ALTER TABLE Members
ADD CONSTRAINT Check_Email_Format
CHECK (Email LIKE '%_@_%_%');


--Create FineRepayment Table

CREATE TABLE FineRepayments (
    RepaymentID int IDENTITY(1,1) PRIMARY KEY,
    MemberID int NOT NULL,
    RepaymentDateTime datetime NOT NULL,
    AmountRepaid decimal(10,2) NOT NULL,
    RepaymentMethod varchar(20) NOT NULL constraint Payment 
	check(RepaymentMethod in ('Card','Cash')),
	PaymentPlan varchar(30) NOT NULL constraint instalment 
	check(PaymentPlan in ('1st Instalment', '2nd Instalment', 'Full Payment'))
    CONSTRAINT FK_FineRepayments_Members 
	FOREIGN KEY (MemberID)
        REFERENCES Members(MemberID)
);

SELECT * FROM FineRepayments

--Create Items Table

CREATE TABLE Items (
    ItemID int IDENTITY(1,1) PRIMARY KEY,
    Title varchar(200) NOT NULL,
    ItemType varchar(20) NOT NULL constraint Item 
	check(ItemType in ('Book', 'Journal', 'DVD', 'Other Media')),
    Author varchar(100) NOT NULL,
    YearOfPublication int NOT NULL,
    DateAddedToCollection date NOT NULL,
    CurrentStatus varchar(20) NOT NULL constraint Status 
	check(CurrentStatus in 
	('On Loan', 'Overdue', 'Available', 'Lost/Removed')),
    ISBN varchar(50)
);

select * from Items


--Create Loans Table

CREATE TABLE Loans (
    LoanID int IDENTITY(1,1) PRIMARY KEY,
    MemberID int NOT NULL,
    ItemID int NOT NULL,
    CONSTRAINT FK_Loans_Members FOREIGN KEY 
	(MemberID)
        REFERENCES Members(MemberID),
    CONSTRAINT FK_Loans_Items FOREIGN KEY (ItemID)
        REFERENCES Items(ItemID)
);

select * from
--Create LoanDetail Table
CREATE TABLE LoanDetail (
    LoanID int PRIMARY KEY,
    LoanDate date NOT NULL,
    DueDate date NOT NULL,
    ReturnDate date,
    CONSTRAINT FK_LoanDetail_Loans 
	FOREIGN KEY (LoanID)
        REFERENCES Loans(LoanID)
);

SELECT * FROM LoanDetail
--Create Book Table

CREATE TABLE Book (
    ItemID int PRIMARY KEY,
    ISBN varchar(50) NOT NULL,
    CONSTRAINT FK_Book_Item FOREIGN KEY (ItemID)
        REFERENCES Items(ItemID)
);


--Create OtherMedia Table

CREATE TABLE OtherMedia (
    ItemID int PRIMARY KEY,
    CONSTRAINT FK_OtherMedia_Item 
	FOREIGN KEY (ItemID)
        REFERENCES Items(ItemID)
);



--Create View OverdueLoans

CREATE VIEW OverdueLoans AS
SELECT Loans.LoanID, Loans.MemberID, Loans.ItemID, Items.Title, 
	   Members.FullName,
       LoanDetail.LoanDate AS DateTakenOut, 
	   LoanDetail.DueDate AS DateDueBack, LoanDetail.ReturnDate,
       DATEDIFF(day, LoanDetail.DueDate, GETDATE())
	   AS DaysOverdue,
       (DATEDIFF(day, LoanDetail.DueDate, GETDATE()) * 0.10)
	   AS FineAmount
FROM Loans
JOIN Members ON Loans.MemberID = Members.MemberID
JOIN Items ON Loans.ItemID = Items.ItemID
JOIN LoanDetail ON Loans.LoanID = LoanDetail.LoanID
WHERE LoanDetail.ReturnDate IS NULL AND 
LoanDetail.DueDate < GETDATE();

SELECT * FROM OverdueLoans

--Create OverdueFines Table
CREATE TABLE OverdueFines (
    MemberID int PRIMARY KEY,
    FineAmount decimal(10,2) NOT NULL DEFAULT 0,
    AmountRepaid decimal(10,2) NOT NULL DEFAULT 0,
    OutstandingBalance AS FineAmount - AmountRepaid,
    CONSTRAINT FK_OverdueFines_Members 
	FOREIGN KEY (MemberID)
        REFERENCES Members(MemberID)
);



--Create ArchivedMembers Table

CREATE TABLE ArchiveMembers (
    ArchiveMemberID int IDENTITY(1,1) PRIMARY KEY,
    MemberID int NOT NULL,
    FullName varchar(100) NOT NULL,
    Address varchar(200) NOT NULL,
    DateOfBirth date NOT NULL,
    Username varchar(50) NOT NULL,
    Password varchar(50) NOT NULL,
    Email varchar(100),
    Telephone varchar(20),
    MembershipEndDate date NOT NULL DEFAULT GETDATE()
);

CREATE TRIGGER Members_Archive
ON Members
AFTER DELETE
AS
BEGIN
INSERT INTO ArchiveMembers (
MemberID, FullName, Address, DateOfBirth, Username, 
Password, Email, Telephone)
SELECT
MemberID, FullName, Address, DateOfBirth, Username, 
Password, Email, Telephone 
FROM deleted
END;

DELETE FROM Members
WHERE MemberID = 3;

Select * from ArchiveMembers

--Question 2 (a.)Stored procedure to search the catalogue by title:

CREATE PROCEDURE SearchByTitle 
    @title NVARCHAR(50)
AS
BEGIN
    SELECT Title, ItemType, Author, YearOfPublication, 
	CurrentStatus
    FROM Items
    WHERE Title LIKE '%' + @title + '%'
    ORDER BY YearOfPublication DESC;
END

-- To Execute the Store Procedure
EXEC SearchByTitle 'Blade Runner';

--Question (2b.)Stored procedure to return a list of items currently on loan with a due date of less than five days:

CREATE PROCEDURE OverdueItems
AS
BEGIN
    SELECT Loans.LoanID, Loans.MemberID, Items.Title, 
	LoanDetail.DueDate,	Members.FullName
    FROM Loans
    JOIN Members ON Loans.MemberID = Members.MemberID
    JOIN Items ON Loans.ItemID = Items.ItemID
    JOIN LoanDetail ON Loans.LoanID = LoanDetail.LoanID
    WHERE LoanDetail.ReturnDate IS NULL 
	AND DATEDIFF(day, DueDate, GETDATE()) > -5 
    AND DATEDIFF(day, DueDate, GETDATE()) <= 0
END



-- To Execute the Store procedure
EXEC OverdueItems;


--Question (2c.)Stored procedure to insert a new member:

CREATE PROCEDURE InsertMember
    @FullName varchar(50),
    @Address varchar(100),
    @DateOfBirth date,
    @Username varchar(20),
    @Password varchar(20),
    @Email varchar(50),
    @Telephone varchar(20)    
AS
BEGIN
    INSERT INTO Members (FullName, Address, 
	DateOfBirth, Username, Password, Email, 
	Telephone)
    VALUES (@FullName, @Address, 
	@DateOfBirth, @Username, @Password, @Email, 
	@Telephone)
END;

--To execute Store Procedure to insert a member
USE [Library]
GO

DECLARE @return_value int

EXEC @return_value = [dbo].[InsertMember]
    @FullName = 'Greg Anthony',
    @Address = '120, Wimslow Road, Manchester',
    @DateOfBirth = '1987-02-01',
    @Username = 'anthony4life',
    @Password = 'g_anthony87',
    @Email = 'a.gregory@hotmail.com',
    @Telephone = '167-82-4402'

SELECT 'Return Value' = @return_value
GO


select * from Members



--Question (2d.)Stored procedure to update the details for an existing member:

CREATE PROCEDURE UpdateMember 
    @MemberID INT,
    @FullName NVARCHAR(50),
    @Address NVARCHAR(100),
    @DateOfBirth DATE,
    @Username NVARCHAR(50),
    @Password NVARCHAR(50),
    @Email NVARCHAR(50),
    @Telephone NVARCHAR(20)
AS
BEGIN
    UPDATE Members
    SET FullName = @FullName,
        Address = @Address,
        DateOfBirth = @DateOfBirth,
        Username = @Username,
        Password = @Password,
        Email = @Email,
        Telephone = @Telephone        
    WHERE MemberID = @MemberID;
END

USE [Library]
GO

DECLARE @return_value int

EXEC @return_value = [dbo].[UpdateMember]
	@MemberID = 8,
    @FullName = 'Greg Anthony',
    @Address = '106, Hulmes Road, Manchester',
    @DateOfBirth = '1987-02-01',
    @Username = 'anthony4life',
    @Password = 'g_anthony87',
    @Email = 'a.gregory@hotmail.com',
    @Telephone = '167-82-4402'

-- To check the new member inserted
select * from Members

--Question (3)  loan history, showing all previous and current 
loans, and including details of the item borrowed, borrowed date, due date and any 
associated fines for each loan

CREATE VIEW LoanHistory AS
SELECT Loans.LoanID, Loans.MemberID, Members.FullName, Items.Title,
		Loans.ItemID, LoanDetail.LoanDate AS DateTakenOut, 
		LoanDetail.DueDate AS DateDueBack, LoanDetail.ReturnDate AS
		DateReturned,
       CASE
            WHEN LoanDetail.ReturnDate IS NOT NULL AND 
			LoanDetail.ReturnDate > LoanDetail.DueDate THEN
                DATEDIFF(day, LoanDetail.DueDate, LoanDetail.ReturnDate) * 0.10
            WHEN LoanDetail.ReturnDate IS NULL AND 
			LoanDetail.DueDate < GETDATE() THEN
                DATEDIFF(day, LoanDetail.DueDate, GETDATE()) * 0.10
            ELSE
                0
       END AS FineAmount
FROM Loans
JOIN Members ON Loans.MemberID = Members.MemberID
JOIN Items ON Loans.ItemID = Items.ItemID
LEFT JOIN LoanDetail ON Loans.LoanID = LoanDetail.LoanID;


-- To check loan history
SELECT *
FROM LoanHistory


--Question (4.) Create a trigger so that the current status of an item automatically updates to Available when the book is returned

CREATE TRIGGER UpdateItemStatus
ON LoanDetail
AFTER UPDATE
AS
BEGIN
    IF UPDATE(ReturnDate)
    BEGIN
        UPDATE Items
        SET CurrentStatus = 'Available'
        FROM Items
        JOIN Loans ON Items.ItemID = Loans.ItemID
        JOIN inserted ON inserted.LoanID = Loans.LoanID
        WHERE inserted.ReturnDate IS NOT NULL
    END
END

--To execute the trigger
EXEC sp_helptrigger 'LoanDetail';

SELECT* FROM Items

--Question 5 You should provide a function, view, or SELECT query which allows the library to 
identify the total number of loans made on a specified date.


SELECT COUNT(*) as TotalLoans
FROM Loans
JOIN LoanDetail ON Loans.LoanID = LoanDetail.LoanID
WHERE LoanDetail.LoanDate = '2023-03-18';


--Question 6


--Insert data into Members Table

INSERT INTO Members (FullName, Address, DateOfBirth, Username, Password, Email,
Telephone)
VALUES ('Rustie Pandey', '24562 Katie Alley, Stapleford','1960-11-03',
'Rustie','rpandy','rpandey0@topsy.com','169-823-4482'),
('Ingeborg Tytherton', '6455 Rockefeller Street, Pentre', '1938-02-12',
'Tytherton', 'borg_1', 'itytherton1@jugem.jp', NULL),
('Garik Rennock', '85208 Coolidge Plaza, Buckland', '1975-10-15',
'Rennock', 'nockrik', 'grennock2@vimeo.com', '904-552-4065'),
('Brinn Merrywether', '59 Derek Hill, Leeds', '1938-02-12',
'Brinn', 'bmwether', NULL, '110-127-3396'),
('Stanislaus Elsie', '9169 Springs Parkway, Bolton', '1985-09-17',
'Elsie', 'el_stan123', 'selsie4@hibu.com', '770-639-5396'),
('Olalekan James', '104 Heyscroft Road, Manshester', '1987-07-23', 
'lekas212', 'on_god', 'lekas@gmail.com', '984-240-8247'),
('Phillip Moore', '1243 Cotton Lodge, Chorlton', '1980-12-04', 
'phillipo', 'moore4u123', 'phillipmoore@yahoo.com', '074-233-1532');


-- To check the data inserted

SELECT * FROM Members



--Insert data into Items Table

INSERT INTO Items (Title, ItemType, Author, YearOfPublication,
DateAddedToCollection, CurrentStatus, ISBN)
VALUES ('Blade Runner', 'DVD', 'Ridley Scot', 1982, '2022-01-01',
'On Loan', NULL),
('The Great Gatsby', 'Book', 'F. Scott Fitzgerald', 1925, '2022-02-05',
'Overdue', '9780743273565'),
('The Shawshank Redemption', 'DVD', 'Frank Darabont', 1994, '2020-03-05',
'Lost/Removed', NULL),
('To Kill a Mockingbird', 'Book', 'Harper Lee', 1960, '2022-04-05',
'Available', '9780061120084'),
('Chronobiology International', 'Journal', 'Informa Healthcare', 2013, '2023-01-01',
'On Loan', '07420528'),
('PowerBi Tools', 'Other Media', 'Microsoft', 2021, '2022-12-15',
'Available', NULL),
('Things Fall Apart', 'Book', 'Wole Soyinka', 1992, '2022-12-17',
'On Loan', '9780435272463');
 
-- To check the data inserted
SELECT * FROM Items

--Insert data into OverdueFines Table

INSERT INTO OverdueFines (MemberID, FineAmount)
SELECT MemberID, FineAmount FROM OverdueLoans;

UPDATE OverdueFines
SET AmountRepaid = FineRepayments.Amount
FROM (
SELECT MemberID, SUM(AmountRepaid) AS Amount
FROM FineRepayments
GROUP BY MemberID
) AS FineRepayments
WHERE OverdueFines.MemberID = FineRepayments.MemberID;

-- To check the data inserted
SELECT * FROM OverdueFines

--Insert data into Loans Table

INSERT INTO Loans (MemberID, ItemID)
VALUES (1, 1),
(2, 2),
(5, 5), 
(6,6),
(7,7);

-- To check the data inserted
SELECT * FROM Loans

--Insert data into LoanDetail Table


INSERT INTO LoanDetail (LoanID, LoanDate, DueDate, ReturnDate)
VALUES (1, '2023-03-18', '2023-04-18', '2023-03-22'),
(2, '2022-12-20', '2023-01-20', NULL),
(3, '2023-03-23', '2023-05-23', NULL),
(4, '2022-12-16', '2022-12-31', NULL),
(5, '2023-03-23', '2023-04-23', NULL);


-- To check the data inserted
select * from LoanDetail


--Insert data into Book Table

INSERT INTO Book (ItemID, ISBN)
VALUES (2, '9780743273565'),
(4, '9780061120084'),
(5, '07420528'),
(7, '9780435272463');

-- To check the data inserted
select * from Book


--Insert data into OtherMedia

INSERT INTO OtherMedia (ItemID)
VALUES (6);

-- To check the data inserted
select * from OtherMedia


--Insert data into FineRepayments
INSERT INTO FineRepayments (MemberID, RepaymentDateTime, 
AmountRepaid, RepaymentMethod, PaymentPlan)
VALUES (2, '2023-02-15 10:00', 2.0, 'Cash', '1st Instalment'),
(6, '2023-02-11 15:00',5.6, 'Card', '1st Instalment');

-- To check the data inserted
select * from FineRepayments



--7 Extra 1

SELECT Members.MemberID, (OverdueFines.FineAmount - 
OverdueFines.AmountRepaid) AS total_fines_owed
FROM Members
JOIN OverdueFines ON Members.MemberID = OverdueFines.MemberID
JOIN (SELECT MemberID, SUM(AmountRepaid) 
AS total_repaid FROM FineRepayments GROUP BY MemberID) AS repaid
ON Members.MemberID = repaid.MemberID
WHERE (OverdueFines.FineAmount - OverdueFines.AmountRepaid)
> repaid.total_repaid;


--Extra 2
CREATE FUNCTION CalculateOverdueFee(@DueDate date, @ReturnDate date)
RETURNS decimal(10,2)
AS  
BEGIN  
    DECLARE @OverdueDays int = 0
    DECLARE @OverdueFee decimal(10,2) = 0
    
    IF @ReturnDate > @DueDate
        SET @OverdueDays = DATEDIFF(day, @DueDate, @ReturnDate)
    
    SET @OverdueFee = @OverdueDays * 0.10
    
    RETURN @OverdueFee
END 

SELECT dbo.CalculateOverdueFee('2022-02-28', '2022-03-03')

--Extra 3


CREATE TRIGGER UpdateItemStatusOnOverdue
ON Loans
FOR INSERT, UPDATE
AS
BEGIN
    UPDATE Items
    SET CurrentStatus = 'Overdue'
    FROM Items
    JOIN inserted ON inserted.ItemID = Items.ItemID
    JOIN LoanDetail ON LoanDetail.LoanID = inserted.LoanID
    WHERE LoanDetail.DueDate < GETDATE()
      AND LoanDetail.ReturnDate IS NULL
END
