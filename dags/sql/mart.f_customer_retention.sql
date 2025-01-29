WITH sales_data AS (
    SELECT 
        s.customer_id,
        s.item_id,
        s.date_id,
        s.quantity,
        s.payment_amount,
        COUNT(*) AS order_count,
        SUM(s.payment_amount) AS total_revenue,
        SUM(CASE WHEN s.order_status = 'refunded' THEN s.quantity ELSE 0 END) AS refunded_quantity
    FROM mart.f_sales s
    JOIN mart.d_item i ON s.item_id = i.item_id
    GROUP BY s.customer_id, s.item_id, s.date_id, s.quantity, s.payment_amount
),
weekly_data AS (
	SELECT 
    TO_DATE(d.date_id::text, 'YYYYMMDD') - (EXTRACT(DOW FROM TO_DATE(d.date_id::text, 'YYYYMMDD'))::integer + 6) % 7 AS week_start,  -- Начало недели (понедельник)
    EXTRACT(week FROM TO_DATE(d.date_id::text, 'YYYYMMDD')) AS week_number,   -- Номер недели
    EXTRACT(year FROM TO_DATE(d.date_id::text, 'YYYYMMDD')) AS year_number     -- Номер года
	FROM 
    	mart.f_sales d
	GROUP BY 
    	week_start, week_number, year_number 
),
customers_data AS (
    SELECT 
        sd.customer_id,
        wd.week_number,
        wd.year_number,
        sd.item_id,
        COUNT(DISTINCT sd.customer_id) FILTER (WHERE sd.order_count = 1) AS new_customers_count,
        COUNT(DISTINCT sd.customer_id) FILTER (WHERE sd.order_count > 1) AS returning_customers_count,
        SUM(sd.total_revenue) FILTER (WHERE sd.order_count = 1) AS new_customers_revenue,
        SUM(sd.total_revenue) FILTER (WHERE sd.order_count > 1) AS returning_customers_revenue,
        SUM(sd.refunded_quantity) AS customers_refunded
    FROM sales_data sd
    JOIN weekly_data wd ON TO_DATE(sd.date_id::text, 'YYYYMMDD') = wd.week_start
    
    GROUP BY sd.customer_id, sd.item_id, wd.week_number, wd.year_number
)

INSERT INTO mart.f_customer_retention (
    new_customers_count,
    returning_customers_count,
    refunded_customer_count,
    period_name,
    period_id,
    item_id,
    new_customers_revenue,
    returning_customers_revenue,
    customers_refunded
)
SELECT 
    new_customers_count,
    returning_customers_count,
    customers_refunded,
    'weekly' AS period_name,
    week_number AS period_id,
    item_id,
    new_customers_revenue,
    returning_customers_revenue,
    customers_refunded
FROM customers_data;
