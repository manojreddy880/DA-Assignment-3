-- 1)*Rank the customers based on the total amount they've spent on rentals.*
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
       SUM(p.amount) AS total_amount_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
ORDER BY total_amount_spent DESC;

-- 2)*Calculate the cumulative revenue generated by each film over time.*
SELECT 
    f.film_id,
    f.title AS film_title,
    p.payment_date,
    SUM(p.amount) OVER (PARTITION BY f.film_id ORDER BY p.payment_date) AS cumulative_revenue
FROM 
    film f
JOIN 
    inventory i ON f.film_id = i.film_id
JOIN 
    rental r ON i.inventory_id = r.inventory_id
JOIN 
    payment p ON r.rental_id = p.rental_id
ORDER BY 
    f.film_id, p.payment_date;


-- 3. *Determine the average rental duration for each film, considering films with similar lengths.*
SELECT 
    f.film_id,
    f.title AS film_title,
    f.rental_duration,
    ROUND(AVG(DATEDIFF(return_date, rental_date)), 2) AS avg_rental_duration
FROM 
    film f
JOIN 
    inventory i ON f.film_id = i.film_id
JOIN 
    rental r ON i.inventory_id = r.inventory_id
GROUP BY 
    f.film_id, f.title, f.rental_duration
ORDER BY 
    f.rental_duration, f.film_id;

-- 4. *Identify the top 3 films in each category based on their rental counts.*
SELECT 
    c.name AS category_name,
    f.title AS film_title,
    COUNT(r.rental_id) AS rental_count
FROM 
    category c
JOIN 
    film_category fc ON c.category_id = fc.category_id
JOIN 
    film f ON fc.film_id = f.film_id
LEFT JOIN 
    inventory i ON f.film_id = i.film_id
LEFT JOIN 
    rental r ON i.inventory_id = r.inventory_id
GROUP BY 
    c.category_id, f.film_id
HAVING 
    rental_count > 0
ORDER BY 
    c.name, rental_count DESC;

-- 5. **Calculate the difference in rental counts between each customer's total rentals and the average rentals
-- across all customers.**
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(r.rental_id) AS total_rentals,
    COUNT(r.rental_id) - avg_rentals.avg_rentals_all_customers AS rental_count_difference
FROM 
    customer c
LEFT JOIN 
    rental r ON c.customer_id = r.customer_id
CROSS JOIN (
    SELECT 
        AVG(sub.total_rentals) AS avg_rentals_all_customers
    FROM (
        SELECT 
            c.customer_id,
            COUNT(r.rental_id) AS total_rentals
        FROM 
            customer c
        LEFT JOIN 
            rental r ON c.customer_id = r.customer_id
        GROUP BY 
            c.customer_id
    ) sub
) avg_rentals
GROUP BY 
    c.customer_id, customer_name, avg_rentals.avg_rentals_all_customers
ORDER BY 
    rental_count_difference DESC;

-- 6. *Find the monthly revenue trend for the entire rental store over time.*
SELECT 
    DATE_FORMAT(p.payment_date, '%Y-%m') AS payment_month,
    SUM(p.amount) AS monthly_revenue
FROM 
    payment p
GROUP BY 
    DATE_FORMAT(p.payment_date, '%Y-%m')
ORDER BY 
    payment_month;

-- 7. *Identify the customers whose total spending on rentals falls within the top 20% of all customers.*
SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) AS customer_name,
    total_amount_spent
FROM (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_amount_spent,
        PERCENT_RANK() OVER (ORDER BY SUM(p.amount) DESC) AS pct_rank
    FROM 
        customer c
    JOIN 
        payment p ON c.customer_id = p.customer_id
    GROUP BY 
        c.customer_id
) ranked_customers
WHERE 
    pct_rank <= 0.2
ORDER BY 
    total_amount_spent DESC;

-- 8. *Calculate the running total of rentals per category, ordered by rental count.* 
SELECT 
    c.name AS category_name,
    f.title AS film_title,
    COUNT(r.rental_id) AS rental_count,
    SUM(COUNT(r.rental_id)) OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS running_total_rentals
FROM 
    category c
JOIN 
    film_category fc ON c.category_id = fc.category_id
JOIN 
    film f ON fc.film_id = f.film_id
LEFT JOIN 
    inventory i ON f.film_id = i.film_id
LEFT JOIN 
    rental r ON i.inventory_id = r.inventory_id
GROUP BY 
    c.category_id, f.film_id
ORDER BY 
    rental_count DESC;

-- 9. *Find the films that have been rented less than the average rental count for their respective categories.*
-- 9th question explanation
SELECT 
    c.name AS category_name,
    AVG(cnt.rental_count) AS avg_category_rental_count
FROM 
    category c
LEFT JOIN (
    SELECT 
        fc.category_id,
        COUNT(r.rental_id) AS rental_count
    FROM 
        film f
    JOIN 
        film_category fc ON f.film_id = fc.film_id
    LEFT JOIN 
        inventory i ON f.film_id = i.film_id
    LEFT JOIN 
        rental r ON i.inventory_id = r.inventory_id
    GROUP BY 
        fc.category_id, f.film_id
) cnt ON c.category_id = cnt.category_id
GROUP BY 
    c.category_id;

SELECT 
    f.title AS film_title,
    c.name AS category_name,
    COUNT(r.rental_id) AS rental_count
FROM 
    film f
JOIN 
    film_category fc ON f.film_id = fc.film_id
JOIN 
    category c ON fc.category_id = c.category_id
LEFT JOIN 
    inventory i ON f.film_id = i.film_id
LEFT JOIN 
    rental r ON i.inventory_id = r.inventory_id
GROUP BY 
    f.film_id, c.category_id;

-- 10)*Identify the top 5 months with the highest revenue and display the revenue generated in each month.*
SELECT 
    DATE_FORMAT(p.payment_date, '%Y-%m') AS payment_month,
    SUM(p.amount) AS total_revenue
FROM 
    payment p
GROUP BY 
    DATE_FORMAT(p.payment_date, '%Y-%m')
ORDER BY 
    total_revenue DESC
LIMIT 5;