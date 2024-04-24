--Запрос считает количество строк в таблице customers
select COUNT(*) as customers_count
from customers;

-- make a table with TOP-10 sellers 
select
    concat(emp.first_name,' ', emp.last_name) as seller,
    count(s.*) as operations,
    floor(sum(p.price * s.quantity)) as income
from sales as s
join employees as emp on s.sales_person_id = emp.employee_id 
join products as p on p.product_id = s.product_id 
group by seller
order by SUM(p.price * s.quantity) desc
limit 10;

-- Make a table with sellers and their operations
with sellers_stat as (
select
    concat(emp.first_name,' ', emp.last_name) as seller,
    count(s.*) as operations,
    floor(sum(p.price * s.quantity)) as income
from sales as s
join employees as emp on s.sales_person_id = emp.employee_id 
join products as p on p.product_id = s.product_id 
group by seller
order by SUM(p.price * s.quantity) desc
),
-- make a variable for total avg income
total_avg_income as (
    select FLOOR(AVG(income / operations)) as total_average_income
    from sellers_stat
)
-- choose sellers who has avg income per operation more total avg income per operation
select
    seller,
    FLOOR(income / operations) as average_income
from sellers_stat, total_avg_income as ta
where FLOOR(income / operations) < ta.total_average_income
order by average_income;

-- make a temp table with all needed data and ordering that in the main request
with tab as (
select
    concat(emp.first_name, ' ', emp.last_name) as seller,
    lower(to_char(s.sale_date, 'Day')) as day_of_week,
    extract(isodow from s.sale_date) as day_number,
    floor(sum(s.quantity * p.price)) as income
from sales as s
join products as p on s.product_id = p.product_id
join employees as emp on emp.employee_id = s.sales_person_id
group by seller, day_of_week, day_number
)
select seller, day_of_week, income
from tab 
order by day_number, seller;

--group all of customers by age groups
select
	case
		when c.age between 16 and 25 then '16-25'
		when c.age between 26 and 40 then '26-40'
		when c.age > 40 then '40+'
	end as age_category,
	count(*) as age_count
from customers as c
group by age_category
order by age_category;

-- group income by month of purchase and unique customers
select
	to_char(sales.sale_date, 'yyyy-mm') as selling_month,
	count(distinct sales.customer_id) as total_customers,
	floor(sum(products.price * sales.quantity)) as income
from sales
join products on products.product_id = sales.product_id 
group by selling_month
order by selling_month;

--find all customers who made first purchase with sale products
with special_offer as (
    select 
    	customers.customer_id,
    	concat(customers.first_name, ' ', customers.last_name) as customer,
        sales.sale_date as sale_date,
   	products.product_id as product_id,
        products.price as price,
        concat(employees.first_name, ' ', employees.last_name) as seller,
	row_number() over (partition by customers.customer_id order by sale_date, price) as row_number
    from customers
    join sales on customers.customer_id = sales.customer_id 
    join employees on employees.employee_id = sales.sales_person_id 
    join products on products.product_id = sales.product_id 
    order by customer_id
)
select
    customer,
    sale_date,
    seller
from special_offer
where row_number = 1 and price = 0;
