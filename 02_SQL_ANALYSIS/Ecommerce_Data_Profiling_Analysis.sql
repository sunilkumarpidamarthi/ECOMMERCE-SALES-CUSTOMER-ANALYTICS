/*
===============================================================================
PROJECT       : E-COMMERCE SALES & CUSTOMER ANALYTICS
SCRIPT        : Ecommerce_Data_Profiling_Analysis.sql
DATABASE      : ecommerce_analytics
PURPOSE       : Data profiling and data-quality assessment of the five raw tables
DBMS          : MySQL 8.0+

IMPORTANT
---------
- This script analyses the raw tables only.
- All statements are read-only SELECT / DESCRIBE queries.
- No source records are inserted, updated, or deleted.
- Review flagged records before making any cleaning decisions.
===============================================================================
*/

USE ecommerce_analytics;


/*=============================================================================
  01. TABLE STRUCTURE REVIEW
  Purpose: Verify columns and imported data types before analysis.
=============================================================================*/

DESCRIBE customers_raw;
DESCRIBE orders_raw;
DESCRIBE order_items_raw;
DESCRIBE products_raw;
DESCRIBE categories_raw;


/*=============================================================================
  02. CUSTOMERS_RAW — DATA PROFILING
=============================================================================*/

/* 2.1 Missing-value profile */
SELECT
    COUNT(*) AS total_rows,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(first_name IS NULL) AS missing_first_name,
    SUM(last_name IS NULL) AS missing_last_name,
    SUM(email IS NULL) AS missing_email,
    SUM(city IS NULL) AS missing_city,
    SUM(registration_date IS NULL) AS missing_registration_date,
    SUM(acquisition_channel IS NULL) AS missing_acquisition_channel
FROM customers_raw;


/* 2.2 Identify duplicate customer IDs */
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customers_raw
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


/* 2.3 Inspect the identified duplicate/conflicting customer records */
SELECT *
FROM customers_raw
WHERE customer_id IN (10089, 10100)
ORDER BY customer_id;


/* 2.4 Identify exact duplicate customer records */
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    registration_date,
    acquisition_channel,
    COUNT(*) AS occurrences
FROM customers_raw
GROUP BY
    customer_id,
    first_name,
    last_name,
    email,
    city,
    registration_date,
    acquisition_channel
HAVING COUNT(*) > 1;


/* 2.5 Check inconsistent text formatting */
SELECT
    customer_id,
    first_name,
    last_name,
    city,
    acquisition_channel
FROM customers_raw
WHERE
    first_name <> TRIM(first_name)
    OR last_name <> TRIM(last_name)
    OR city <> TRIM(city)
    OR acquisition_channel <> TRIM(acquisition_channel)
    OR city <> CONCAT(
        UPPER(LEFT(TRIM(city), 1)),
        LOWER(SUBSTRING(TRIM(city), 2))
    )
ORDER BY customer_id;


/* 2.6 Identify registration dates that cannot be parsed as YYYY-MM-DD */
SELECT
    customer_id,
    registration_date,
    STR_TO_DATE(registration_date, '%Y-%m-%d') AS parsed_date
FROM customers_raw
WHERE registration_date IS NOT NULL
  AND TRIM(registration_date) <> ''
  AND STR_TO_DATE(registration_date, '%Y-%m-%d') IS NULL;


/* 2.7 Check whether registration dates follow the expected text format */
SELECT
    customer_id,
    registration_date
FROM customers_raw
WHERE registration_date IS NOT NULL
  AND TRIM(registration_date) <> ''
  AND registration_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';


/* 2.8 Check blank or whitespace-only text values */
SELECT
    SUM(TRIM(first_name) = '') AS blank_first_name,
    SUM(TRIM(last_name) = '') AS blank_last_name,
    SUM(TRIM(email) = '') AS blank_email,
    SUM(TRIM(city) = '') AS blank_city,
    SUM(TRIM(registration_date) = '') AS blank_registration_date,
    SUM(TRIM(acquisition_channel) = '') AS blank_acquisition_channel
FROM customers_raw;


/* 2.9 Inspect customer records with blank last name, city, or acquisition channel */
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    registration_date,
    acquisition_channel
FROM customers_raw
WHERE TRIM(last_name) = ''
   OR TRIM(city) = ''
   OR TRIM(acquisition_channel) = ''
ORDER BY customer_id;


/*=============================================================================
  03. ORDERS_RAW — DATA PROFILING
=============================================================================*/

/* 3.1 Missing-value profile */
SELECT
    COUNT(*) AS total_rows,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(order_date IS NULL) AS missing_order_date,
    SUM(status IS NULL) AS missing_status,
    SUM(shipping_method IS NULL) AS missing_shipping_method
FROM orders_raw;


/* 3.2 Identify duplicate order IDs */
SELECT
    order_id,
    COUNT(*) AS occurrences
FROM orders_raw
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


/* 3.3 Inspect the identified duplicate/conflicting order records */
SELECT *
FROM orders_raw
WHERE order_id IN (50061, 50076)
ORDER BY order_id;


/* 3.4 Check order-date text formats */
SELECT
    order_id,
    order_date
FROM orders_raw
WHERE order_date IS NOT NULL
  AND TRIM(order_date) <> ''
  AND order_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';


/* 3.5 Review order-status values and their frequency */
SELECT
    status,
    COUNT(*) AS order_count
FROM orders_raw
GROUP BY status
ORDER BY order_count DESC;


/* 3.6 Identify orders referencing customers absent from customers_raw */
SELECT
    o.order_id,
    o.customer_id
FROM orders_raw AS o
LEFT JOIN customers_raw AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


/* 3.7 Check blank or whitespace-only order fields */
SELECT
    SUM(TRIM(order_date) = '') AS blank_order_date,
    SUM(TRIM(status) = '') AS blank_status,
    SUM(TRIM(shipping_method) = '') AS blank_shipping_method
FROM orders_raw;


/* 3.8 Inspect orders with blank status or shipping method */
SELECT
    order_id,
    customer_id,
    order_date,
    status,
    shipping_method
FROM orders_raw
WHERE TRIM(status) = ''
   OR TRIM(shipping_method) = ''
ORDER BY order_id;


/*=============================================================================
  04. ORDER_ITEMS_RAW — DATA PROFILING
=============================================================================*/

/* 4.1 Missing-value profile */
SELECT
    COUNT(*) AS total_rows,
    SUM(order_item_id IS NULL) AS missing_order_item_id,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(product_id IS NULL) AS missing_product_id,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(unit_price IS NULL) AS missing_unit_price,
    SUM(discount IS NULL) AS missing_discount
FROM order_items_raw;


/* 4.2 Check blank quantity, unit-price, and discount values */
SELECT
    SUM(TRIM(CAST(quantity AS CHAR)) = '') AS blank_quantity,
    SUM(TRIM(unit_price) = '') AS blank_unit_price,
    SUM(TRIM(discount) = '') AS blank_discount
FROM order_items_raw;


/* 4.3 Inspect rows with missing quantity or blank discount */
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount
FROM order_items_raw
WHERE quantity IS NULL
   OR TRIM(discount) = ''
ORDER BY order_item_id;


/* 4.4 Identify negative quantities or unit prices */
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount
FROM order_items_raw
WHERE quantity < 0
   OR (
        TRIM(unit_price) REGEXP '^-?[0-9,]+(\\.[0-9]+)?$'
        AND CAST(REPLACE(TRIM(unit_price), ',', '') AS DECIMAL(10,2)) < 0
   )
ORDER BY order_item_id;


/* 4.5 Check unit-price and discount text formats */
SELECT
    order_item_id,
    unit_price,
    discount
FROM order_items_raw
WHERE TRIM(unit_price) NOT REGEXP '^[0-9,]+(\\.[0-9]+)?$'
   OR (
        TRIM(discount) <> ''
        AND TRIM(discount) NOT REGEXP '^[0-9]+(\\.[0-9]+)?%?$'
   )
ORDER BY order_item_id;


/* 4.6 Review distinct discount values and their frequency */
SELECT
    TRIM(discount) AS discount_value,
    COUNT(*) AS occurrences
FROM order_items_raw
GROUP BY TRIM(discount)
ORDER BY occurrences DESC;


/* 4.7 Identify repeated order-item combinations */
SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    discount,
    COUNT(*) AS occurrences
FROM order_items_raw
GROUP BY
    order_id,
    product_id,
    quantity,
    unit_price,
    discount
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


/* 4.8 Identify order items referencing orders absent from orders_raw */
SELECT
    oi.order_item_id,
    oi.order_id
FROM order_items_raw AS oi
LEFT JOIN orders_raw AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


/* 4.9 Identify order items referencing products absent from products_raw */
SELECT
    oi.order_item_id,
    oi.product_id
FROM order_items_raw AS oi
LEFT JOIN products_raw AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


/*=============================================================================
  05. PRODUCTS_RAW — DATA PROFILING
=============================================================================*/

/* 5.1 Missing-value profile */
SELECT
    COUNT(*) AS total_rows,
    SUM(product_id IS NULL) AS missing_product_id,
    SUM(product_name IS NULL) AS missing_product_name,
    SUM(category_id IS NULL) AS missing_category_id,
    SUM(selling_price IS NULL) AS missing_selling_price,
    SUM(list_price IS NULL) AS missing_list_price
FROM products_raw;


/* 5.2 Check blank product names and category IDs */
SELECT
    SUM(TRIM(product_name) = '') AS blank_product_name,
    SUM(TRIM(CAST(category_id AS CHAR)) = '') AS blank_category_id
FROM products_raw;


/* 5.3 Identify duplicate product IDs */
SELECT
    product_id,
    COUNT(*) AS occurrences
FROM products_raw
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


/* 5.4 Identify zero or negative product prices */
SELECT
    product_id,
    product_name,
    selling_price,
    list_price
FROM products_raw
WHERE selling_price <= 0
   OR list_price <= 0;


/* 5.5 Identify selling prices greater than list prices */
SELECT
    product_id,
    product_name,
    selling_price,
    list_price
FROM products_raw
WHERE selling_price > list_price;


/* 5.6 Check product-name formatting */
SELECT
    product_id,
    product_name
FROM products_raw
WHERE product_name <> TRIM(product_name)
   OR BINARY product_name <> BINARY CONCAT(
        UPPER(LEFT(TRIM(product_name), 1)),
        LOWER(SUBSTRING(TRIM(product_name), 2))
   );


/* 5.7 Identify products referencing category IDs absent from categories_raw */
SELECT
    p.product_id,
    p.product_name,
    p.category_id
FROM products_raw AS p
LEFT JOIN categories_raw AS c
    ON p.category_id = c.category_id
WHERE p.category_id IS NOT NULL
  AND c.category_id IS NULL;


/*=============================================================================
  06. CATEGORIES_RAW — DATA PROFILING
=============================================================================*/

/* 6.1 Missing-value profile */
SELECT
    COUNT(*) AS total_rows,
    SUM(category_id IS NULL) AS missing_category_id,
    SUM(category_name IS NULL) AS missing_category_name
FROM categories_raw;


/* 6.2 Check blank category names */
SELECT
    SUM(TRIM(category_name) = '') AS blank_category_name
FROM categories_raw;


/* 6.3 Inspect categories with blank names */
SELECT
    category_id,
    category_name
FROM categories_raw
WHERE TRIM(category_name) = '';


/* 6.4 Identify duplicate category IDs */
SELECT
    category_id,
    COUNT(*) AS occurrences
FROM categories_raw
GROUP BY category_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


/*=============================================================================
  07. DOCUMENTED DATA-PROFILING FINDINGS
  These are the findings recorded during the original analysis. They are
  included as comments for project documentation; running this script does
  not automatically re-validate or modify these findings.
=============================================================================

CUSTOMERS_RAW — 302 rows
- Exact duplicate customer record: customer_id 10089.
- Conflicting customer ID: 10100 (different cities).
- Formatting issues in customer name/city.
- One invalid registration date: 31/13/2024.
- Blank last name, city, and acquisition channel.

ORDERS_RAW — 1,002 rows
- Exact duplicate order: order_id 50061.
- Conflicting order ID: 50076.
- Mixed date formats and one invalid date.
- One blank status and one blank shipping method.
- Misspelled status: 'deliverd'.
- Four orders reference missing customer 10067.

ORDER_ITEMS_RAW — 1,743 rows
- One missing quantity and one blank discount.
- Negative quantity and negative unit price.
- Price stored as 1,299.00 and discount stored as 10%.
- One exact duplicate row.
- One invalid order reference and one invalid product reference.

PRODUCTS_RAW — 43 rows
- Exact duplicate product: product_id 1005.
- Conflicting selling prices for product_id 1021.
- Missing category ID and list price.
- Negative selling price for product_id 1013.
- Inconsistent formatting for product name associated with product_id 1003.
- All non-NULL category IDs match existing categories.

CATEGORIES_RAW — 9 rows
- Blank category name for category_id 6.
- Exact duplicate category ID 1 (Electronics).
- No SQL NULL values.

===============================================================================
END OF SCRIPT
===============================================================================
