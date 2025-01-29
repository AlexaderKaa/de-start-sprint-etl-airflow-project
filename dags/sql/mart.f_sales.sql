INSERT INTO mart.f_sales (date_id, item_id, customer_id, city_id, quantity, payment_amount, order_status) 
SELECT 
    dc.date_id,
    uol.item_id,
    uol.customer_id,
    uol.city_id,
    -- Учитываем возвраты: если заказ refunded, делаем количество отрицательным
    uol.quantity * CASE WHEN COALESCE(uol.order_status, 'shipped') = 'refunded' THEN -1 ELSE 1 END AS quantity,
    -- Учитываем возвраты: если заказ refunded, делаем сумму отрицательной
    uol.payment_amount * CASE WHEN COALESCE(uol.order_status, 'shipped') = 'refunded' THEN -1 ELSE 1 END AS payment_amount,
    -- Если статус отсутствует, по умолчанию считаем его shipped
    COALESCE(uol.order_status, 'shipped') AS order_status
FROM 
    staging.user_order_log uol
LEFT JOIN 
    mart.d_calendar dc 
    ON uol.date_time::DATE = dc.date_actual
WHERE 
    uol.date_time::DATE = '{{ds}}';