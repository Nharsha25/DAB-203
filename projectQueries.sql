

select top 5 * from olist_customers_dataset
select top 5 * from olist_order_items_dataset
select top 5 * from olist_orders_dataset
select top 5 * from olist_sellers_dataset
select top 5 * from olist_order_payments_dataset


--Top 10 sales product categories
SELECT top 10 product_category_name, 
ROUND(SUM(price),2) AS price
FROM olist_products_dataset pd
INNER JOIN olist_order_items_dataset oit ON oit.product_id = pd.product_id
GROUP BY product_category_name
ORDER BY price DESC

--Average delivery time Interval
;WITH average_time AS 
      (
	  SELECT DATEDIFF ( DAY , order_purchase_timestamp , order_delivered_customer_date  ) AS delivery_time 
      FROM olist_orders_dataset 
      WHERE order_status = 'delivered'
      )
     SELECT AVG(delivery_time) AS "Average_Delivery_Time_Interval_(Estimated_vs_Actual)" 
     FROM average_time

--Which day of the week, customers tend to go shopping
SELECT DATEPART(WEEKDAY, CONVERT(DATE, order_purchase_timestamp)) as day_of_week, 
COUNT(order_id) AS sales
FROM olist_orders_dataset
GROUP BY DATEPART(WEEKDAY, CONVERT(DATE, order_purchase_timestamp))
order by day_of_week

--Popular payment types
SELECT payment_type,
       COUNT(order_id) AS num_payments
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY num_payments DESC;

--Top 3 Sellers
SELECT purchase_year, seller_id, total_revenue, value_rank
FROM (SELECT purchase_year, seller_id,
             SUM(t1.revenue) AS total_revenue,
             RANK() OVER (PARTITION BY purchase_year ORDER BY SUM(t1.revenue) DESC)
             AS value_rank
      FROM (SELECT order_id, YEAR(order_purchase_timestamp) AS purchase_year
            FROM olist_orders_dataset
            WHERE order_status = 'delivered') o
      JOIN (SELECT seller_id, order_id,
                   ROUND(SUM(price) + SUM(freight_value),2)
                   AS revenue
            FROM olist_order_items_dataset
            GROUP BY seller_id, order_id) t1
      ON o.order_id = t1.order_id
      GROUP BY purchase_year, seller_id) t2
WHERE value_rank IN (1,2,3);

--Which day of the week, customers tend to do shopping
SELECT DATEPART(WEEKDAY, CONVERT(DATE, order_purchase_timestamp)) as day_of_week, 
COUNT(order_id) AS sales
FROM olist_orders_dataset
GROUP BY DATEPART(WEEKDAY, CONVERT(DATE, order_purchase_timestamp))
order by day_of_week

--query calculates the percentage of orders arriving within 2 days, 1 week, 2 weeks, or more than 2 weeks after they are placed.
SELECT ROUND(CAST(SUM(case when DATEDIFF(day,CONVERT(DATE, o.order_purchase_timestamp),CONVERT(DATE,  o.order_delivered_customer_date)) < = 2 then 1 else 0 end) as float)/CAST(COUNT(o.order_id) as float)*100,2)
       AS under_two_days,
	  ROUND(CAST(SUM(case when DATEDIFF(day,CONVERT(DATE, o.order_purchase_timestamp),
             CONVERT(DATE,  o.order_delivered_customer_date)) BETWEEN 3 AND 5 then 1 else 0 end) as float)/CAST(COUNT(o.order_id) as float)*100,2)
       AS in_one_week,
	ROUND(CAST(SUM(case when DATEDIFF(day,CONVERT(DATE, o.order_purchase_timestamp),
             CONVERT(DATE,  o.order_delivered_customer_date)) BETWEEN 6 AND 14 then 1 else 0 end) as float)/CAST(COUNT(o.order_id) as float)*100,2)
       AS in_two_weeks,
	ROUND(CAST(SUM(case when DATEDIFF(day,CONVERT(DATE, o.order_purchase_timestamp),
             CONVERT(DATE,  o.order_delivered_customer_date)) > 14 then 1 else 0 end) as float)/CAST(COUNT(o.order_id) as float)*100,2)
       AS more_than_two_weeks
	   from olist_orders_dataset o
WHERE o.order_status = 'delivered'
AND CONVERT(varchar,o.order_delivered_customer_date) != '0000-00-00 00:00:00'
AND DATEDIFF(day,CONVERT(DATE, o.order_purchase_timestamp),
             CONVERT(DATE,  o.order_delivered_customer_date)) >= 0;

--highest average order value and which business segment they belong
SELECT top 10 t1.seller_id, business_segment,
       ROUND(cast(total_order_value as float)/cast(num_orders as float)*100,2)
       AS avg_order_value
FROM (SELECT seller_id,
             COUNT(DISTINCT order_id)
             AS num_orders,
             SUM(price) + SUM(freight_value)
             AS total_order_value
      FROM olist_order_items_dataset
      GROUP BY seller_id) t1
JOIN olist_closed_deals_dataset d
ON t1.seller_id = d.seller_id
ORDER BY avg_order_value DESC;

-- ontime delivery rate of each month for respective years

SELECT MONTH(order_purchase_timestamp) AS pusrchase_month,
       COUNT(DISTINCT seller_id) AS num_sellers
FROM (SELECT oi.seller_id, o.order_purchase_timestamp
            FROM olist_orders_dataset o JOIN olist_order_items_dataset oi
            ON o.order_id = oi.order_id
            WHERE order_status = 'delivered'
           AND CONVERT(varchar,o.order_delivered_customer_date) != '0000-00-00 00:00:00'
            AND DATEDIFF(day,CONVERT(DATE, o.order_delivered_customer_date),
             CONVERT(DATE,  o.order_estimated_delivery_date)) >= 0
) a
GROUP BY MONTH(order_purchase_timestamp)
ORDER BY MONTH(order_purchase_timestamp);


--TOP 5 Selling sellers by city data:-
;WITH temp_sellers AS ( 
SELECT a.seller_city AS seller_city, 
COUNT(b.order_id) AS sales_qty, 
COUNT(b.order_id) * 100.0 / 
SUM(COUNT(b.order_id)) OVER () AS temp_sales_percentage 
FROM olist_sellers_dataset AS a 
INNER JOIN olist_order_items_dataset AS b 
ON a.seller_id = b.seller_id 
GROUP BY seller_city 
--ORDER BY sales_qty DESC 
) SELECT top 5 seller_city, 
sales_qty, 
temp_sales_percentage AS sales_percentage FROM temp_sellers 
