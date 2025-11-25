DROP TABLE IF EXISTS books;
CREATE TABLE books (
		isbn	VARCHAR(50) PRIMARY KEY,
		book_title	VARCHAR(70),
		category	VARCHAR(20),
		rental_price	FLOAT,
		status	VARCHAR(5),
		author	VARCHAR(50),
		publisher VARCHAR(50)
	);
	
DROP TABLE IF EXISTS branch;
	CREATE TABLE branch(
		branch_id	VARCHAR(30) PRIMARY KEY,
		manager_id	VARCHAR(6),
		branch_address	VARCHAR(20),
		contact_no VARCHAR(20)
	);

DROP TABLE IF EXISTS employees;
	CREATE TABLE employees (
		emp_id	VARCHAR(6) PRIMARY KEY,
		emp_name	VARCHAR(20),
		position	VARCHAR(10),
		salary	INT,
		branch_id VARCHAR(10) REFERENCES branch(branch_id)
	);
ALTER TABLE employees
ALTER COLUMN salary TYPE NUMERIC(19,2)
DROP TABLE IF EXISTS issued_status;
	CREATE TABLE issued_status (
		issued_id	 VARCHAR(20) PRIMARY KEY,
		issued_member_id VARCHAR(6) REFERENCES members(member_id),
		issued_book_name VARCHAR(70),
		issued_date	 DATE,
		issued_book_isbn	VARCHAR(20) REFERENCES books(isbn),
		issued_emp_id VARCHAR(6) REFERENCES employees(emp_id)
	);
	
DROP TABLE IF EXISTS members;
	CREATE TABLE members (
		member_id	VARCHAR(20) PRIMARY KEY,
		member_name	VARCHAR(20),
		member_address	VARCHAR(20),
		reg_date DATE
);

DROP TABLE IF EXISTS return_status;
	CREATE TABLE return_status (
		return_id	VARCHAR(6) PRIMARY KEY,
		issued_id	VARCHAR(6), -- Can't use this as a foreign key because the values on this column of this table arent the same as the values of this column in the issued_status table.
		return_book_name	VARCHAR(6),  
		return_date	DATE,
		return_book_isbn VARCHAR(6) -
);

SELECT * FROM  books;
SELECT * FROM  branch;
SELECT * FROM  employees;
SELECT * FROM  issued_status;
SELECT * FROM  members;
SELECT * FROM  return_status;

-- Task 1. Listing Members Who Have Issued More Than One Book
SELECT 
member_name,
COUNT(*)
FROM issued_status
JOIN members ON issued_status.issued_member_id = members.member_id
GROUP BY 1
HAVING COUNT(*) > 1;

-- Task 2.  Creating a Summary Table using CTAS to generate new tables based on query results - each book and total book_issued_cnt
CREATE TABLE issued_book_cnt AS
SELECT 
book_title,
COUNT(issued_book_name) AS book_issued_cnt
FROM issued_status
JOIN books ON issued_book_isbn = books.isbn
GROUP BY 1
ORDER BY 2;

--TEST the CTAS I just made
SELECT * FROM issued_book_cnt ;

-- Task 3.  Same as Task 2 but no without an inner join and I will not make a CTAS table
SELECT 
issued_book_name,
COUNT(*) AS book_issued_count
from issued_status
GROUP BY 1
ORDER BY 2;

-- Task 4. Finding Total Rental Income by Category
SELECT 
category,
SUM(rental_price) AS total_rental_income_by_Category,
COUNT(*)
FROM issued_status
JOIN books ON issued_status.issued_book_isbn = books.isbn
GROUP BY 1
ORDER BY 2 DESC;

--TASK 5. Listing Members Who Registered in the Last 180 Days
SELECT member_name FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 DAYS';

-- Task 6. Listing Employees with Their Branch Manager's NAME and their branch details (branch.*)- a short way to say all columns of the branch table
SELECT
employees.emp_id,
employees.emp_name,
employees.position,
employees.salary,
branch.* ,
manager.emp_name as manager
FROM employees
JOIN branch on employees.branch_id = branch.branch_id
JOIN employees AS manager
ON branch.manager_id = manager.emp_id ;

-- Task 7. Creating a Table of Books with Rental Price Above a Certain Threshold
CREATE TABLE highend_books
AS
SELECT * FROM  books
WHERE rental_price >= 7
ORDER BY rental_price ASC;

--Task 8. Retrieving the List of Books Not Yet Returned 

SELECT *
FROM issued_status 
LEFT JOIN return_status ON  issued_status.issued_id = return_status.issued_id
WHERE return_id IS NULL ;

/* Task 9. Identifying Members with Overdue Books**  
Writing a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue
CURRENT_DATE 2024-07-01 */
SELECT
member_id,
member_name, 
issued_book_name, 
issued_date, 
return_date,
(DATE '2024-07-01' - return_date - 30) || ' ' || 'Days' AS Overdue
FROM issued_status
JOIN return_status ON issued_status.issued_id = return_status.issued_id
JOIN members ON issued_status.issued_member_id = members.member_id;

/*Task 10: Updating Book Status on Return**  
Writing a query to update the status of books in the books table to "Yes" when they are 
returned (based on entries in the return_status table). */
CREATE OR REPLACE PROCEDURE returned_books(p_return_id VARCHAR(6), p_issued_id VARCHAR(6)) -- DATES not prefered
LANGUAGE plpgsql
AS $$

DECLARE
	-- every variable that has been mentioned in the SELECT section under BEGIN has to be declared here for them to be recognised
    v_isbn VARCHAR(20);  
    v_book_name VARCHAR(70);
    
BEGIN
    -- Here i will write all the logic and code
    -- inserting into return_table based on users input and autoamtically changing books table status (books.status)
    INSERT INTO return_status(return_id, issued_id, return_date)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE);  

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO 
	    v_isbn,   -
	    v_book_name 
		FROM  issued_status
		WHERE issued_id = p_issued_id;
	
	UPDATE books
    SET status = 'Yes'
    WHERE isbn = '978-0-307-58837-1'; 

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;    
END;
$$


-- Testing FUNCTION returned_books
-- Lets start. Book '978-0-307-58837-1' has been returned

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1'; --TO check its issued_id, in this case IS135

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- User calling function 
CALL returned_books('RS138', 'IS135');

-- User calling another function etc.
CALL returned_books('RS148', 'IS140');

/* TASK 11. Branch Performance Report  
Creating a query that generates a performance report for each branch, showing the number of books issued, 
the number of books returned, and the total revenue generated from book rentals.      */

CREATE TABLE branch_report
AS
SELECT 
branch.branch_id,
COUNT(issued_status.issued_id) AS number_of_books_issued,
COUNT(return_id) AS numer_of_books_returned,
SUM(rental_price) AS total_reveneue
FROM issued_status
JOIN employees ON employees.emp_id = issued_status.issued_emp_id
JOIN branch ON employees.branch_id = branch.branch_id
JOIN books ON issued_status.issued_book_isbn = books.isbn
LEFT JOIN return_status ON issued_status.issued_id = return_status.issued_id -- If i dont LEFT JOIN then I will lose records
GROUP BY 1;

/* TASK 12. CTAS: Creating a Table of Active Members 
Using the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members
who have issued at least one book in the last 2 months. CURRENT_DATE = DATE '2024-07-01'   */
 
CREATE TABLE active_members 
AS
SELECT 
member_id,
member_name,
issued_date
FROM issued_status
JOIN members ON issued_status.issued_member_id = members.member_id
WHERE issued_date >= DATE '2024-07-01' - INTERVAL '3 MONTH'
GROUP BY 1,2, 3

/* Task 13: Finding Employees with the Most Book Issues Processed 
Writing a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch. */

SELECT 
emp_id,
emp_name,
COUNT(issued_book_isbn) AS books_issued_per_employee
FROM issued_status
JOIN employees ON issued_status.issued_emp_id = employees.emp_id
JOIN branch on employees.branch_id = branch.branch_id
GROUP BY 1,2
ORDER BY 3 DESC LIMIT 3;

/* Task 14: Stored Procedure**
Creating a stored procedure to manage the status of books in a library system.
First I write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows:
The stored procedure should take the book_id as an input parameter.
The procedure should first check if the book is available (status = 'yes').
If the book is available, it should be issued, and the status in the books table should be updated to 'no'.
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available. */


SELECT * FROM books
WHERE isbn = '978-0-7434-7679-3'  -- Status=Yes, its available, which means open for issue

INSERT INTO issued_status (issued_id VARCHAR(20), issued_member_id VARCHAR(6), issued_book_name VARCHAR(70), issued_book_isbn VARCHAR(20), issued_emp_id VARCHAR(6))
VALUES ()  -- That will be added by the User, now lets start with the procedure

CREATE OR REPLACE PROCEDURE book_status (p_issued_id VARCHAR(20), p_issued_member_id VARCHAR(6), p_issued_book_name VARCHAR(70), p_issued_book_isbn VARCHAR(20), p_issued_emp_id VARCHAR(6))
LANGUAGE plpgsql 
AS $$ 
	
	DECLARE
		v_status VARCHAR(5);
		v_book_title VARCHAR(70);

	BEGIN  
		SELECT 
		status
		INTO
		v_status  
		FROM books
		WHERE isbn = p_issued_book_isbn;
		
		IF v_status = 'Yes'
		THEN 
		INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
		VALUES (p_issued_id, p_issued_member_id, p_issued_book_name, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id) ;

		UPDATE books
		SET status = 'No'
		WHERE isbn = p_issued_book_isbn;
		
		RAISE NOTICE 'The book : % is ready available for issue', p_issued_book_name ;
		ELSE 
		RAISE NOTICE 'The book : % is currently not available', p_issued_book_name ;
		END IF;


	END;
$$


)
-- test 978-0-7434-7679-3
SELECT * FROM books
WHERE isbn = '978-0-7434-7679-3'  -- Status: Yes

CALL book_status('IS141', 'C110', 'Storm Of Swords','978-0-7434-7679-3', 'E105' ) 

SELECT * FROM books
WHERE isbn = '978-0-7434-7679-3'  -- Status is now: No

-- Lets test another isbn
SELECT * FROM books
WHERE isbn = '978-0-06-440055-8'   -- Status : No

CALL book_status('IS142', 'C109', 'A Dance With Dragons','978-0-06-440055-8', 'E104' ) -- NOTICE:  The book : A Dance With Dragons is currently not available
SELECT * FROM books
WHERE isbn = '978-0-06-440055-8'   -- Status : No 

/* Task 15 Creating Table As Select (CTAS)
Creating a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
Writing a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    The number of overdue books.
    The total fines, with each day's fine calculated at $0.50.
    The number of books issued by each member.
    The resulting table should show:
    Member ID
    Number of overdue books
    Total fines
	CURRENT_DATE - DATE 2024-07-01 */
	
CREATE TABLE fines
AS
WITH data AS
(SELECT
	member_id,
	member_name,
	issued_date,
	return_date,
	(DATE '2024-07-01' - return_date - 30) AS Overdue
	FROM issued_status
JOIN members on issued_status.issued_member_id = members.member_id
JOIN return_status on issued_status.issued_id = return_status.issued_id
	WHERE (DATE '2024-07-01' - return_date - 30) > 0 )
SELECT
    member_id,
	member_name,
	Overdue || ' ' || 'Days' AS overdue_days,
	'$' || ' ' || 0.50 * Overdue AS total_fines
	FROM data ;
