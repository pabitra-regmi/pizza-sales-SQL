CREATE DATABASE pizzahut;
USE pizzahut;


 SELECT * FROM orders;
 SELECT * FROM pizza_types;
 SELECT * FROM pizzas;
 SELECT * FROM order_details;

--Retrieve the total number of orders placed.
SELECT COUNT(order_id) AS total_order FROM orders;

--Calculate the total revenue generated from pizza sales.
SELECT
 ROUND(SUM(o.quantity*p.price),2) AS total_sale 
 FROM order_details o
 JOIN pizzas p
 ON o.pizza_id = p.pizza_id;

 --Identify the highest-priced pizza.
SELECT price, name
FROM (
    SELECT p.price,
           t.name,
           DENSE_RANK() OVER (ORDER BY p.price DESC) AS rnk
    FROM pizza_types t
    JOIN pizzas p
      ON t.pizza_type_id = p.pizza_type_id
) r 
WHERE rnk = 1;

--Identify the most common pizza size ordered.
SELECT TOP 1 p.size,COUNT(*) AS toppick FROM pizzas p
JOIN order_details t 
ON p.pizza_id=t.pizza_id
GROUP BY P.size
ORDER BY toppick DESC;

--List the top 5 most ordered pizza types along with their quantities.
SELECT TOP 5 
    p.pizza_type_id, 
    SUM(o.quantity) AS mostpick
FROM pizzas p
JOIN order_details o 
    ON p.pizza_id = o.pizza_id
GROUP BY p.pizza_type_id
ORDER BY mostpick DESC;

--Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
    pt.category,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_quantity DESC;

--Determine the distribution of orders by hour of the day.
SELECT 
    DATEPART(HOUR, o.time) AS order_hour,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
GROUP BY DATEPART(HOUR, o.time)
ORDER BY order_hour;

--Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
    pt.category,
    SUM(od.quantity) AS total_pizzas
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_pizzas DESC;

--Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    AVG(daily_total) AS avg_pizzas_per_day
FROM (
    SELECT 
        CAST(o.date AS DATE) AS order_date,
        SUM(od.quantity) AS daily_total
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY CAST(o.date AS DATE)
) t;

--Determine the top 3 most ordered pizza types based on revenue.
SELECT TOP 3
    pt.name,
    SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_revenue DESC;

--Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
    pt.name,
    SUM(od.quantity * p.price) AS revenue,
    ROUND(SUM(od.quantity * p.price) * 100.0 / SUM(SUM(od.quantity * p.price)) OVER(),2) AS percentage_of_total
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY percentage_of_total DESC;

--Analyze the cumulative revenue generated over time.
SELECT 
    CAST(o.date AS DATE) AS order_date,
    ROUND( SUM(od.quantity * p.price),2) AS daily_revenue,
    ROUND(SUM(SUM(od.quantity * p.price)) OVER (ORDER BY CAST(o.date AS DATE)),2) AS cumulative_revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
GROUP BY CAST(o.date AS DATE)
ORDER BY order_date;

--Determine the top 3 most ordered pizza types based on revenue for each pizza category.
WITH revenue_per_type AS (
    SELECT 
        pt.category,
        pt.name,
        SUM(od.quantity * p.price) AS total_revenue
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
)
SELECT
    category,
    name,
    total_revenue
FROM (
    SELECT 
        *,
        RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS rnk
    FROM revenue_per_type
) t
WHERE rnk <= 3
ORDER BY category, rnk;

