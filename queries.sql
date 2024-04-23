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
	LOWER(to_char(s.sale_date, 'Day')) AS day_of_week,
	EXTRACT(isodow FROM s.sale_date) AS day_number,
	FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
JOIN products AS p ON s.product_id = p.product_id
JOIN employees AS emp ON emp.employee_id = s.sales_person_id
GROUP BY seller, day_of_week, day_number
)
SELECT seller, day_of_week, income
FROM tab 
ORDER BY day_number, seller;

--Group all of customers by age groups
SELECT
	CASE
		WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
		WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
		WHEN c.age > 40 THEN '40+'
	END AS age_category,
	COUNT(*) AS age_count
FROM customers AS c
GROUP BY age_category
ORDER BY age_category;

-- Group income by month of purchase and unique customers
SELECT
	TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
	COUNT(DISTINCT sales.customer_id) AS total_customers,
	FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
JOIN products ON products.product_id = sales.product_id 
GROUP BY selling_month
ORDER BY selling_month;

--Find all customers who made first purchase with sale products
WITH customers_purchases AS (
    SELECT
    	customers.customer_id,
    	CONCAT(customers.first_name, ' ', customers.last_name) AS customer,
    	sales.sale_date,
    	products.product_id,
    	products.price,
    	CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    	ROW_NUMBER()
    		OVER (PARTITION BY customers.customer_id ORDER BY sales.sale_date, products.price) AS row_number
    	FROM sales
    	JOIN products ON products.product_id = sales.sales_id 
    	JOIN customers ON customers.customer_id = sales.customer_id
    	JOIN employees ON sales.sales_person_id = employees.employee_id
    	ORDER BY customers.customer_id, sales.sale_date, products.price
)
SELECT
	customer,
	sale_date,
	seller
FROM customers_purchases
WHERE row_number = 1 AND price = 0
ORDER BY customer_id;
