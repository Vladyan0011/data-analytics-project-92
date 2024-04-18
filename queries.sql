--Запрос считает количество строк в таблице customers
select COUNT(*) as customers_count
from customers;

-- make a table with TOP-10 sellers 
SELECT
	CONCAT(emp.first_name,' ', emp.last_name) AS seller,
	COUNT(s.*) AS operations,
	FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN employees AS emp ON s.sales_person_id = emp.employee_id 
JOIN products AS p ON p.product_id = s.product_id 
GROUP BY seller
ORDER BY SUM(p.price * s.quantity) DESC
LIMIT 10;

-- Make a table with sellers and their operations
WITH sellers_stat AS (
SELECT
	CONCAT(emp.first_name,' ', emp.last_name) AS seller,
	COUNT(s.*) AS operations,
	FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN employees AS emp ON s.sales_person_id = emp.employee_id 
JOIN products AS p ON p.product_id = s.product_id 
GROUP BY seller
ORDER BY SUM(p.price * s.quantity) DESC
),
-- make a variable for total avg income
total_avg_income AS (
    SELECT FLOOR(AVG(income / operations)) AS total_average_income
    FROM sellers_stat
)
-- choose sellers who has avg income per operation more total avg income per operation
SELECT
    seller,
    FLOOR(income / operations) AS average_income
FROM sellers_stat, total_avg_income as ta
WHERE FLOOR(income / operations) < ta.total_average_income
ORDER BY average_income;

-- make a temp table with all needed data and ordering that in the main request
WITH tab AS (
SELECT
	CONCAT(emp.first_name, ' ', emp.last_name) AS seller,
	to_char(s.sale_date, 'Day') AS day_of_week,
	EXTRACT(DOW FROM s.sale_date) + 1 AS day_number,
	FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
JOIN products AS p ON s.product_id = p.product_id
JOIN employees AS emp ON emp.employee_id = s.sales_person_id
GROUP BY seller, day_of_week, day_number
)
SELECT seller, day_of_week, income
FROM tab 
ORDER BY day_number, seller;
