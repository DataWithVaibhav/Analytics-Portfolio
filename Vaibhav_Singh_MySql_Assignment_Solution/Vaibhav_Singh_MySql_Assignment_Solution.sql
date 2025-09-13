-- MySQL Assignment Solutions (Classic Models) - Corrected Version
-- Run in MySQL 8.0+ after loading classicmodels dataset
SHOW DATABASES;

-- =========================================================
-- Q1. SELECT clause with WHERE, AND, DISTINCT, LIKE
-- Question: Fetch the employee number, first name, and last name of those employees who are working as Sales Rep reporting to employee with employeenumber 1102.
USE classicmodels;
-- a) Employees who are Sales Rep reporting to employee 1102
SELECT e.employeeNumber, e.firstName, e.lastName
FROM employees e
WHERE e.jobTitle = 'Sales Rep' AND e.reportsTo = 1102;

-- Question: Show the unique productline values containing the word cars at the end from the products table.
-- b) Unique productLine values ending with 'cars'
SELECT DISTINCT p.productLine
FROM products p
WHERE LOWER(p.productLine) LIKE '% cars';

-- =========================================================
-- Q2. CASE statements for segmentation
-- Question: Segment customers into three categories based on country (North America, Europe, Other).
SELECT c.customerNumber, c.customerName,
       CASE
         WHEN c.country IN ('USA','Canada') THEN 'North America'
         WHEN c.country IN ('UK','France','Germany') THEN 'Europe'
         ELSE 'Other'
       END AS CustomerSegment
FROM customers c;

-- =========================================================
-- Q3. GROUP BY + HAVING; Date/Time functions
-- a) Question: Identify the top 10 products by total quantity ordered.
SELECT od.productCode, SUM(od.quantityOrdered) AS total_qty
FROM orderdetails od
GROUP BY od.productCode
ORDER BY total_qty DESC
LIMIT 10;

-- b) Question: Analyze payment frequency by month where total payments > 20, sort descending by count.
SELECT MONTHNAME(p.paymentDate) AS month_name, COUNT(*) AS total_payments
FROM payments p
GROUP BY MONTH(p.paymentDate), MONTHNAME(p.paymentDate)
HAVING COUNT(*) > 20
ORDER BY total_payments DESC;

-- =========================================================
-- Q4. Constraints
-- Question: Create Customers_Orders DB with Customers and Orders tables having required constraints.
DROP DATABASE IF EXISTS Customers_Orders;
CREATE DATABASE Customers_Orders;
USE Customers_Orders;

CREATE TABLE Customers (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(50) NOT NULL,
  last_name  VARCHAR(50) NOT NULL,
  email      VARCHAR(255) UNIQUE,
  phone_number VARCHAR(20)
);

CREATE TABLE Orders (
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  order_date DATE,
  total_amount DECIMAL(10,2),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
  CONSTRAINT chk_total_amount_positive CHECK (total_amount > 0)
);

USE classicmodels;

-- =========================================================
-- Q5. JOINS
-- Question: List the top 5 countries by order count.
SELECT c.country, COUNT(*) AS order_count
FROM orders o
JOIN customers c ON c.customerNumber = o.customerNumber
GROUP BY c.country
ORDER BY order_count DESC
LIMIT 5;

-- =========================================================
-- Q6. SELF JOIN
-- Question: Create table project, insert employees, and display employees with their managers.
DROP TABLE IF EXISTS project;
CREATE TABLE project (
  EmployeeID INT PRIMARY KEY AUTO_INCREMENT,
  FullName   VARCHAR(50) NOT NULL,
  Gender     ENUM('Male','Female') NOT NULL,
  ManagerID  INT NULL
);

INSERT INTO project (FullName, Gender, ManagerID) VALUES
('Diane Murphy','Female', NULL),
('Mary Patterson','Female', 1),
('William Patterson','Male', 2),
('Gerard Bondur','Male', 2),
('Pamela Castillo','Female', 4),
('Larry Bott','Male', 4),
('Mami Nishi','Female', 2);

SELECT e.EmployeeID, e.FullName AS EmployeeName, m.FullName AS ManagerName
FROM project e
LEFT JOIN project m ON e.ManagerID = m.EmployeeID
ORDER BY e.EmployeeID;

-- =========================================================
-- Q7. DDL Commands
-- Question: Create table facility, alter it to add PK, auto_increment, and city column.
DROP TABLE IF EXISTS facility;
CREATE TABLE facility (
  Facility_ID INT,
  Name   VARCHAR(100),
  State  VARCHAR(100),
  Country VARCHAR(100)
);

ALTER TABLE facility
  MODIFY COLUMN Facility_ID INT NOT NULL AUTO_INCREMENT,
  ADD PRIMARY KEY (Facility_ID);

ALTER TABLE facility
  ADD COLUMN City VARCHAR(100) NOT NULL AFTER Name;

-- =========================================================
-- Q8. Views
-- Question: Create a view product_category_sales for product line wise sales analysis.
DROP VIEW IF EXISTS product_category_sales;
CREATE VIEW product_category_sales AS
SELECT pl.productLine,
       SUM(od.quantityOrdered * od.priceEach) AS total_sales,
       COUNT(DISTINCT o.orderNumber) AS number_of_orders
FROM productlines pl
JOIN products p ON p.productLine = pl.productLine
JOIN orderdetails od ON od.productCode = p.productCode
JOIN orders o ON o.orderNumber = od.orderNumber
GROUP BY pl.productLine;

-- =========================================================
-- Q9. Stored Procedures
-- Question: Create a procedure Get_country_payments that takes year and country as input and returns total payments in K.
DROP PROCEDURE IF EXISTS Get_country_payments;
DELIMITER //
CREATE PROCEDURE Get_country_payments(IN inYear INT, IN inCountry VARCHAR(50))
BEGIN
  SELECT YEAR(p.paymentDate) AS `year`,
         c.country,
         CONCAT(ROUND(SUM(p.amount)/1000), 'K') AS total_amount_K
  FROM customers c
  JOIN payments p ON p.customerNumber = c.customerNumber
  WHERE YEAR(p.paymentDate) = inYear AND c.country = inCountry
  GROUP BY YEAR(p.paymentDate), c.country;
END //
DELIMITER ;

-- =========================================================
-- Q10. Window functions
-- a) Question: Rank customers by order frequency using rank and dense_rank.
WITH order_counts AS (
  SELECT o.customerNumber, COUNT(*) AS order_count
  FROM orders o
  GROUP BY o.customerNumber
)
SELECT oc.customerNumber, c.customerName, oc.order_count,
       RANK() OVER (ORDER BY oc.order_count DESC) AS `rank`,
       DENSE_RANK() OVER (ORDER BY oc.order_count DESC) AS `dense_rank`
FROM order_counts oc
JOIN customers c ON c.customerNumber = oc.customerNumber
ORDER BY oc.order_count DESC;

-- b) Question: Calculate year wise, month wise order counts and YoY percentage change.
WITH monthly AS (
  SELECT 
    YEAR(orderDate) AS `Year`, 
    MONTH(orderDate) AS month_num,
    DATE_FORMAT(orderDate, '%M') AS `Month`,
    COUNT(*) AS `Total Orders`
  FROM orders
  GROUP BY YEAR(orderDate), MONTH(orderDate), DATE_FORMAT(orderDate, '%M')
)
SELECT 
  m.`Year`, 
  m.`Month`, 
  m.`Total Orders`,
  CASE
    WHEN LAG(m.`Total Orders`) OVER (ORDER BY m.`Year`, m.month_num) IS NULL THEN NULL
    WHEN LAG(m.`Total Orders`) OVER (ORDER BY m.`Year`, m.month_num) = 0 THEN NULL
    ELSE CONCAT(
      ROUND(
        ((m.`Total Orders` - LAG(m.`Total Orders`) OVER (ORDER BY m.`Year`, m.month_num)) / 
        LAG(m.`Total Orders`) OVER (ORDER BY m.`Year`, m.month_num)) * 100, 
      0), 
      '%'
    )
  END AS `% YoY Change`
FROM monthly m
ORDER BY m.`Year`, m.month_num;

-- =========================================================
-- Q11. Subqueries
-- Question: Count product lines with buyPrice above average buyPrice.
SELECT p.productLine, COUNT(*) AS product_count_above_avg
FROM products p
WHERE p.buyPrice > (SELECT AVG(buyPrice) FROM products)
GROUP BY p.productLine
ORDER BY product_count_above_avg DESC;

-- =========================================================
-- Q12. Error Handling
-- Question: Create table Emp_EH and procedure InsertEmpEH with error handling.
DROP TABLE IF EXISTS Emp_EH;
CREATE TABLE Emp_EH (
  EmpID INT PRIMARY KEY,
  EmpName VARCHAR(100),
  EmailAddress VARCHAR(100)
);

-- Drop the procedure if it already exists
DROP PROCEDURE IF EXISTS InsertEmpEH;

DELIMITER //
CREATE PROCEDURE InsertEmpEH(IN p_id INT, IN p_name VARCHAR(100), IN p_email VARCHAR(100))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    SELECT 'Error occurred' AS Message;
  END;
  INSERT INTO Emp_EH (EmpID, EmpName, EmailAddress)
  VALUES (p_id, p_name, p_email);
END //
DELIMITER ;

-- =========================================================
-- Q13. Triggers
-- Question: Create table Emp_BIT and a before insert trigger to ensure Working_hours is positive.
DROP TABLE IF EXISTS Emp_BIT;
CREATE TABLE Emp_BIT (
  Name VARCHAR(50),
  Occupation VARCHAR(50),
  Working_date DATE,
  Working_hours INT
);

INSERT INTO Emp_BIT VALUES
('Robin', 'Scientist', '2020-10-04', 12),
('Warner', 'Engineer', '2020-10-04', 10),
('Peter', 'Actor', '2020-10-04', 13),
('Marco', 'Doctor', '2020-10-04', 14),
('Brayden', 'Teacher', '2020-10-04', 12),
('Antonio', 'Business', '2020-10-04', 11);

DELIMITER //
CREATE TRIGGER trg_before_insert_empbit
BEFORE INSERT ON Emp_BIT
FOR EACH ROW
BEGIN
  IF NEW.Working_hours < 0 THEN
    SET NEW.Working_hours = ABS(NEW.Working_hours);
  END IF;
END//
DELIMITER ;
