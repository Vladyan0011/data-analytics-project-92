-- Запрос считает количество строк в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;

-- Создание таблицы с ТОП-10 продавцов 
SELECT
    CONCAT(emp.first_name, ' ', emp.last_name) AS seller,
    COUNT(s.*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN employees AS emp ON s.sales_person_id = emp.employee_id
JOIN products AS p ON s.product_id = p.product_id
GROUP BY seller
ORDER BY SUM(p.price * s.quantity) DESC
LIMIT 10;

-- Создание таблицы с продавцами и их операциями
WITH sellers_stat AS (
    SELECT
        CONCAT(emp.first_name, ' ', emp.last_name) AS seller,
        COUNT(s.*) AS operations,
        FLOOR(SUM(p.price * s.quantity)) AS income
    FROM sales AS s
    JOIN employees AS emp ON sales.sales_person_id = employees.employee_id
    JOIN products AS p ON sales.product_id = products.product_id
    GROUP BY seller
    ORDER BY SUM(p.price * s.quantity) DESC
),

-- Создание переменной для общего среднего дохода
total_avg_income AS (
    SELECT FLOOR(AVG(income / operations)) AS total_average_income
    FROM sellers_stat
)

-- Выбор продавцов, у которых средний доход за операцию 
-- меньше общего среднего дохода за операцию
SELECT
    st.seller,
    FLOOR(st.income / st.operations) AS average_income
FROM sellers_stat AS st, total_avg_income AS ta
WHERE FLOOR(st.income / st.operations) < ta.total_average_income
ORDER BY average_income;

-- Создание временной таблицы со всеми необходимыми
-- данными и их упорядочивание в основном запросе
WITH tab AS (
    SELECT
        CONCAT(emp.first_name, ' ', emp.last_name) AS seller,
        LOWER(TO_CHAR(s.sale_date, 'Day')) AS day_of_week,
        EXTRACT(ISODOW FROM s.sale_date) AS day_number,
        FLOOR(SUM(s.quantity * p.price)) AS income
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    JOIN employees AS emp ON s.sales_person_id = emp.employee_id
    GROUP BY seller, day_of_week, day_number
)

SELECT
    seller,
    day_of_week,
    income
FROM tab
ORDER BY day_number, seller;

-- Группировка всех клиентов по возрастным группам
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

-- Группировка доходов по месяцам покупок и уникальным клиентам
SELECT
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
JOIN products ON sales.product_id = products.product_id
GROUP BY selling_month
ORDER BY selling_month;

-- Поиск всех клиентов, совершивших первую покупку со скидочными продуктами
WITH special_offer AS (
    SELECT
        customers.customer_id,
        CONCAT(customers.first_name, ' ', customers.last_name) AS customer,
        sales.sale_date AS sale_date,
        products.product_id AS product_id,
        products.price AS price,
        CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
        ROW_NUMBER()
            OVER (PARTITION BY customers.customer_id ORDER BY sale_date, price)
            AS row_number
    FROM customers
    JOIN sales ON customers.customer_id = sales.customer_id
    JOIN employees ON sales.sales_person_id = employees.employee_id
    JOIN products ON sales.product_id = products.product_id
    ORDER BY customers.customer_id
)

SELECT
    customer,
    sale_date,
    seller
FROM special_offer
WHERE row_number = 1 AND price = 0;
