-- Monday Coffee -- Data Analysis 

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date)  = 2023
	AND
	EXTRACT(quarter FROM sale_date) = 4



SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city


SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_pr_cx
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC


-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name



-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM -- table
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
	-- ORDER BY 1, 3 DESC
) as t1
WHERE rank <= 3


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;



SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;



DO $$
DECLARE
    threshold NUMERIC := 10000;
    rec RECORD;
BEGIN
    -- Loop through the sales and calculate total spent by each customer
    FOR rec IN 
        SELECT c.customer_id, c.customer_name, SUM(s.total) AS total_spent
        FROM sales s
        JOIN customers c ON s.customer_id = c.customer_id
        GROUP BY c.customer_id, c.customer_name
        HAVING SUM(s.total) > threshold
    LOOP
        -- Insert VIP customers only if they don't already exist
        IF NOT EXISTS (SELECT 1 FROM vip_customers WHERE customer_id = rec.customer_id) THEN
            INSERT INTO vip_customers (customer_id, customer_name, total_spent)
            VALUES (rec.customer_id, rec.customer_name, rec.total_spent);
        END IF;
    END LOOP;
END $$;

-- SELECT * FROM vip_customers;
-- ALTER TABLE vip_customers
-- ADD COLUMN city_name VARCHAR(15);



----First part Ends Here
---Thank you for providing the schema. Based on the schema you have shared, here are the PL/SQL queries for the business problems you previously mentioned:

1. Identify VIP Customers (customers who spent more than $10,000)
sql
Copy code
DECLARE
    threshold NUMBER := 10000;
BEGIN
    -- Insert VIP customers who spent more than the threshold
    FOR r IN (
        SELECT c.customer_id, c.customer_name, SUM(s.total) AS total_spent
        FROM sales s
        JOIN customers c ON s.customer_id = c.customer_id
        GROUP BY c.customer_id, c.customer_name
        HAVING SUM(s.total) > threshold
    ) LOOP
        INSERT INTO vip_customers (customer_id, customer_name, total_spent)
        VALUES (r.customer_id, r.customer_name, r.total_spent);
    END LOOP;

    COMMIT;
END;
2. Generate Monthly Sales Reports
sql
Copy code
BEGIN
    -- Generate Monthly Sales Reports for each city
    FOR r IN (
        SELECT ci.city_name, 
               EXTRACT(MONTH FROM s.sale_date) AS sale_month, 
               SUM(s.total) AS total_sales
        FROM sales s
        JOIN customers c ON s.customer_id = c.customer_id
        JOIN city ci ON c.city_id = ci.city_id
        GROUP BY ci.city_name, EXTRACT(MONTH FROM s.sale_date)
    ) LOOP
        INSERT INTO monthly_sales_report (city_name, sale_month, total_sales)
        VALUES (r.city_name, r.sale_month, r.total_sales);
    END LOOP;

    COMMIT;
END;
3. Track Low-Performing Products (products with less than 100 sales)
sql
Copy code
DECLARE
    threshold INT := 100;
BEGIN
    -- Mark products with sales less than the threshold
    FOR r IN (
        SELECT p.product_id, p.product_name, COUNT(s.sale_id) AS sale_count
        FROM products p
        LEFT JOIN sales s ON p.product_id = s.product_id
        GROUP BY p.product_id, p.product_name
        HAVING COUNT(s.sale_id) < threshold
    ) LOOP
        UPDATE products
        SET product_status = 'Review'
        WHERE product_id = r.product_id;
    END LOOP;

    COMMIT;
END;
4. Calculate Customer Loyalty Score (based on total spent and number of purchases)
sql
Copy code
BEGIN
    -- Calculate and update loyalty scores for each customer
    FOR r IN (
        SELECT c.customer_id, 
               SUM(s.total) AS total_spent, 
               COUNT(s.sale_id) AS purchase_count
        FROM sales s
        JOIN customers c ON s.customer_id = c.customer_id
        GROUP BY c.customer_id
    ) LOOP
        UPDATE customers
        SET loyalty_score = (r.total_spent / 1000) + r.purchase_count
        WHERE customer_id = r.customer_id;
    END LOOP;

    COMMIT;
END;
5. Monitor City-Wise Rent to Revenue Ratio
sql
Copy code
BEGIN
    -- Monitor and calculate the rent-to-revenue ratio for each city
    FOR r IN (
        SELECT ci.city_name, 
               ci.estimated_rent, 
               SUM(s.total) AS total_revenue
        FROM city ci
        JOIN customers c ON ci.city_id = c.city_id
        JOIN sales s ON s.customer_id = c.customer_id
        GROUP BY ci.city_name, ci.estimated_rent
    ) LOOP
        IF r.total_revenue > 0 THEN
            -- Insert rent-to-revenue ratio for cities with revenue greater than 0
            INSERT INTO city_rent_ratio (city_name, rent_revenue_ratio)
            VALUES (r.city_name, r.estimated_rent / r.total_revenue);
        END IF;
    END LOOP;

    COMMIT;
END;
6. Restocking Alerts for Products with Low Stock
sql
Copy code
DECLARE
    threshold INT := 50;  -- Low stock threshold
BEGIN
    -- Create restocking alerts for products with stock below threshold
    FOR r IN (
        SELECT p.product_id, p.product_name, p.stock
        FROM products p
        WHERE p.stock < threshold
    ) LOOP
        -- Insert alert for restocking
        INSERT INTO restocking_alerts (product_id, product_name, stock)
        VALUES (r.product_id, r.product_name, r.stock);
    END LOOP;

    COMMIT;
END;


-- 11. Identify Cities with Highest Potential for Expansion (based on revenue and population)

BEGIN
    -- Identify potential cities for expansion based on revenue and population
    FOR r IN (
        SELECT ci.city_name, 
               SUM(s.total) AS total_revenue, 
               ci.population
        FROM city ci
        JOIN customers c ON ci.city_id = c.city_id
        JOIN sales s ON s.customer_id = c.customer_id
        GROUP BY ci.city_name, ci.population
        HAVING SUM(s.total) > 50000 AND ci.population > 1000000  -- Adjust criteria
    ) LOOP
        INSERT INTO potential_cities (city_name, total_revenue, customer_count, population)
        VALUES (r.city_name, r.total_revenue, COUNT(s.customer_id), r.population);
    END LOOP;

    COMMIT;
END;



-- **********************************************************************
DO $$
DECLARE
    threshold INT := 10000;
    low_stock_threshold INT := 50;
    product_sales_threshold INT := 100;
    city_expansion_revenue_threshold INT := 50000;
    city_expansion_population_threshold INT := 1000000;
BEGIN
    -- 1. Identify VIP Customers (customers who spent more than $10,000)
    FOR r IN (
        SELECT c.customer_id, c.customer_name, SUM(s.total) AS total_spent
        FROM sales s
        JOIN customers c ON s.customer_id = c.customer_id
        GROUP BY c.customer_id, c.customer_name
        HAVING SUM(s.total) > threshold
    ) LOOP
        INSERT INTO vip_customers (customer_id, customer_name, total_spent)
        VALUES (r.customer_id, r.customer_name, r.total_spent);
    END LOOP;

    -- 2. Generate Monthly Sales Reports for each city
    FOR r IN (
        SELECT ci.city_name, 
               EXTRACT(MONTH FROM s.sale_date) AS sale_month, 
               SUM(s.total) AS total_sales
        FROM sales s
        JOIN customers c ON s.customer_id = c.customer_id
        JOIN city ci ON c.city_id = ci.city_id
        GROUP BY ci.city_name, EXTRACT(MONTH FROM s.sale_date)
    ) LOOP
        INSERT INTO monthly_sales_report (city_name, sale_month, total_sales)
        VALUES (r.city_name, r.sale_month, r.total_sales);
    END LOOP;

    -- 3. Track Low-Performing Products (products with less than 100 sales)
    FOR r IN (
        SELECT p.product_id, p.product_name, COUNT(s.sale_id) AS sale_count
        FROM products p
        LEFT JOIN sales s ON p.product_id = s.product_id
        GROUP BY p.product_id, p.product_name
        HAVING COUNT(s.sale_id) < product_sales_threshold
    ) LOOP
        UPDATE products
        SET product_status = 'Review'
        WHERE product_id = r.product_id;
    END LOOP;

    -- 4. Calculate Customer Loyalty Score (based on total spent and number of purchases)
    FOR r IN (
        SELECT c.customer_id, 
               SUM(s.total) AS total_spent, 
               COUNT(s.sale_id) AS purchase_count
        FROM sales s
        JOIN customers c ON s.customer_id = c.customer_id
        GROUP BY c.customer_id
    ) LOOP
        UPDATE customers
        SET loyalty_score = (r.total_spent / 1000) + r.purchase_count
        WHERE customer_id = r.customer_id;
    END LOOP;

    -- 5. Monitor City-Wise Rent to Revenue Ratio
    FOR r IN (
        SELECT ci.city_name, 
               ci.estimated_rent, 
               SUM(s.total) AS total_revenue
        FROM city ci
        JOIN customers c ON ci.city_id = c.city_id
        JOIN sales s ON s.customer_id = c.customer_id
        GROUP BY ci.city_name, ci.estimated_rent
    ) LOOP
        IF r.total_revenue > 0 THEN
            INSERT INTO city_rent_ratio (city_name, rent_revenue_ratio)
            VALUES (r.city_name, r.estimated_rent / r.total_revenue);
        END IF;
    END LOOP;

    -- 6. Restocking Alerts for Products with Low Stock
    FOR r IN (
        SELECT p.product_id, p.product_name, p.stock
        FROM products p
        WHERE p.stock < low_stock_threshold
    ) LOOP
        INSERT INTO restocking_alerts (product_id, product_name, stock)
        VALUES (r.product_id, r.product_name, r.stock);
    END LOOP;

    -- 7. Identify Cities with Highest Potential for Expansion (based on revenue and population)
    FOR r IN (
        SELECT ci.city_name, 
               SUM(s.total) AS total_revenue, 
               ci.population
        FROM city ci
        JOIN customers c ON ci.city_id = c.city_id
        JOIN sales s ON s.customer_id = c.customer_id
        GROUP BY ci.city_name, ci.population
        HAVING SUM(s.total) > city_expansion_revenue_threshold 
           AND ci.population > city_expansion_population_threshold
    ) LOOP
        INSERT INTO potential_cities (city_name, total_revenue, customer_count, population)
        VALUES (r.city_name, r.total_revenue, COUNT(s.customer_id), r.population);
    END LOOP;


-- Added some new collumn
ALTER TABLE products
ADD COLUMN average_rating FLOAT;

    -- 8. Calculate Average Customer Rating for Products
DO $$
DECLARE
    r RECORD;  -- Declare a record to hold the result of the SELECT query
BEGIN
    -- Loop through the result of the SELECT query
    FOR r IN (
        SELECT p.product_id, 
               p.product_name, 
               AVG(s.rating) AS avg_rating
        FROM sales s
        JOIN products p ON s.product_id = p.product_id
        GROUP BY p.product_id, p.product_name
    ) LOOP
        -- Update the products table with the average rating
        UPDATE products
        SET average_rating = r.avg_rating
        WHERE product_id = r.product_id;
    END LOOP;

    -- Commit the changes
    COMMIT;
END $$;

-- creating the relation of the vip custome with another table 
ALTER TABLE vip_customers
ADD CONSTRAINT fk_vip_customers_customers
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

/// make the relation 
SELECT conname
FROM pg_constraint
WHERE conrelid = 'sales'::regclass;

UPDATE sales
SET customer_id = r.customer_id
FROM vip_customers r
WHERE sales.customer_id = r.customer_id;

SELECT DISTINCT s.customer_id
FROM sales s
WHERE NOT EXISTS (
    SELECT 1 FROM vip_customers v WHERE v.customer_id = s.customer_id
);

DO $$
DECLARE
    threshold NUMERIC := 10000;
    r RECORD;  -- Declare r as a RECORD type to hold the result of each row
BEGIN
    -- Insert missing VIP customers who spent more than the threshold
    FOR r IN (
        SELECT c.customer_id, c.customer_name, SUM(s.total) AS total_spent
        FROM sales s
        JOIN customers c ON s.customer_id = c.customer_id
        GROUP BY c.customer_id, c.customer_name
        HAVING SUM(s.total) > threshold
    ) LOOP
        -- Insert only if customer_id doesn't exist in vip_customers
        INSERT INTO vip_customers (customer_id, customer_name, total_spent)
        SELECT r.customer_id, r.customer_name, r.total_spent
        WHERE NOT EXISTS (
            SELECT 1 FROM vip_customers WHERE customer_id = r.customer_id
        );
    END LOOP;
END $$;



SELECT DISTINCT s.customer_id
FROM sales s
LEFT JOIN vip_customers v ON s.customer_id = v.customer_id
WHERE v.customer_id IS NULL;

INSERT INTO vip_customers (customer_id, customer_name, total_spent)
SELECT s.customer_id, c.customer_name, SUM(s.total) AS total_spent
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE s.customer_id NOT IN (SELECT customer_id FROM vip_customers)
GROUP BY s.customer_id, c.customer_name;


ALTER TABLE sales
ADD CONSTRAINT fk_sales_vip_customers
FOREIGN KEY (customer_id) REFERENCES vip_customers(customer_id);

-- second relation sussfull

-- 3 step 
ALTER TABLE vip_customers
ADD COLUMN purchase_count INT;

-- step 4
UPDATE vip_customers vc
SET purchase_count = (
    SELECT COUNT(s.sale_id)
    FROM sales s
    WHERE s.customer_id = vc.customer_id
);
-- city_name associated with each customer and order the result by total_spent in descending order.
SELECT vc.customer_id, 
       vc.customer_name, 
       vc.total_spent, 
       vc.purchase_count, 
       ci.city_name
FROM vip_customers vc
JOIN customers c ON vc.customer_id = c.customer_id
JOIN city ci ON c.city_id = ci.city_id
ORDER BY vc.total_spent DESC;

--  add the city of vip customer 
CREATE OR REPLACE PROCEDURE update_vip_customer_city()
LANGUAGE plpgsql
AS
$$
BEGIN
    -- Update city_name for each VIP customer
    UPDATE vip_customers vc
    SET city_name = ci.city_name
    FROM customers c
    JOIN city ci ON c.city_id = ci.city_id
    WHERE vc.customer_id = c.customer_id;
    
    -- Optional commit if needed for explicit transaction handling
    COMMIT;
END;
$$;


CALL update_vip_customer_city();



select * from  vip_customers;




