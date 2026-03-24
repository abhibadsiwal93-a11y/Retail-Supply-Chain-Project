CREATE DATABASE retail_supply_chain;
USE retail_supply_chain;
CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100),
    contact_name VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    country VARCHAR(50)
);
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10,2),
    supplier_id INT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);
CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(100),
    city VARCHAR(50),
    capacity INT
);
CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    product_id INT,
    warehouse_id INT,
    stock_quantity INT,
    last_updated DATE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    product_id INT,
    quantity_sold INT,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
DROP TABLE inventory;
DROP TABLE sales;
DROP TABLE product;
DROP TABLE suppliers;
DROP TABLE warehouses;
CREATE TABLE suppliers (
    product_id INT PRIMARY KEY,
    supplier_type VARCHAR(100),
    lead_time_days INT
);
SELECT COUNT(*) FROM suppliers;
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    category VARCHAR(100),
    cost_price DECIMAL(10,2),
    selling_price DECIMAL(10,2)
);
SELECT COUNT(*) FROM products;
CREATE TABLE inventory (
    product_id INT,
    warehouse_id INT,
    stock_quantity INT,
    reorder_level INT
);
SELECT COUNT(*) FROM inventory;
CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    region VARCHAR(100)
);
CREATE TABLE sales (
    order_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    order_date DATE,
    region VARCHAR(100),
    warehouse_id INT
);
DROP TABLE sales;
CREATE TABLE sales (
    order_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    order_date VARCHAR(20),
    region VARCHAR(100),
    warehouse_id INT
);
SELECT COUNT(*) FROM sales;
TRUNCATE TABLE sales;
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';
LOAD DATA LOCAL INFILE 'C:/Users/Abhi/Downloads/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, product_id, quantity, order_date, region, warehouse_id);
SHOW VARIABLES LIKE 'secure_file_priv';
TRUNCATE TABLE sales;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(order_id, product_id, quantity, order_date, region, warehouse_id);
SELECT COUNT(*) FROM sales;
WITH inventory_summary AS (
    SELECT 
        product_id,
        SUM(stock_quantity) AS total_stock
    FROM inventory
    GROUP BY product_id
)
-- INVENTORY TURNOVER RATIO
SELECT 
    p.product_id,
    SUM(s.quantity * p.cost_price) AS total_cogs,
    i.total_stock * p.cost_price AS inventory_value,
    SUM(s.quantity * p.cost_price) / 
    (i.total_stock * p.cost_price) AS inventory_turnover_ratio
FROM sales s
JOIN products p 
    ON s.product_id = p.product_id
JOIN inventory_summary i 
    ON s.product_id = i.product_id
GROUP BY p.product_id, i.total_stock, p.cost_price
ORDER BY inventory_turnover_ratio DESC;
-- DEAD PRODUCT IDENTIFICATION
SELECT 
    product_id,
    MAX(order_date) AS last_sale_date
FROM sales
GROUP BY product_id;
SELECT MAX(order_date) FROM sales;
WITH max_date AS (
    SELECT MAX(STR_TO_DATE(order_date, '%m/%d/%Y')) AS reference_date
    FROM sales
),
last_sales AS (
    SELECT 
        product_id,
        MAX(STR_TO_DATE(order_date, '%m/%d/%Y')) AS last_sale_date
    FROM sales
    GROUP BY product_id
)

SELECT 
    i.product_id,
    i.stock_quantity,
    ls.last_sale_date,
    DATEDIFF(md.reference_date, ls.last_sale_date) AS days_since_last_sale,
    CASE 
        WHEN DATEDIFF(md.reference_date, ls.last_sale_date) <= 30 THEN 'Healthy'
        WHEN DATEDIFF(md.reference_date, ls.last_sale_date) <= 90 THEN 'Slow Moving'
        ELSE 'Dead Stock'
    END AS stock_status
FROM inventory i
LEFT JOIN last_sales ls 
    ON i.product_id = ls.product_id
CROSS JOIN max_date md
WHERE i.stock_quantity > 0
ORDER BY days_since_last_sale DESC;
WITH max_date AS (
    SELECT MAX(STR_TO_DATE(order_date, '%m/%d/%Y')) AS reference_date
    FROM sales
),
last_sales AS (
    SELECT 
        product_id,
        MAX(STR_TO_DATE(order_date, '%m/%d/%Y')) AS last_sale_date
    FROM sales
    GROUP BY product_id
)

SELECT 
    i.product_id,
    i.stock_quantity,
    p.cost_price,
    (i.stock_quantity * p.cost_price) AS dead_stock_value,
    DATEDIFF(md.reference_date, ls.last_sale_date) AS days_since_last_sale
FROM inventory i
LEFT JOIN last_sales ls 
    ON i.product_id = ls.product_id
JOIN products p 
    ON i.product_id = p.product_id
CROSS JOIN max_date md
WHERE 
    i.stock_quantity > 0
    AND DATEDIFF(md.reference_date, ls.last_sale_date) > 90
ORDER BY dead_stock_value DESC;
SELECT 
    SUM(i.stock_quantity * p.cost_price) AS total_dead_stock_value
FROM inventory i
LEFT JOIN (
    SELECT 
        product_id,
        MAX(STR_TO_DATE(order_date, '%m/%d/%Y')) AS last_sale_date
    FROM sales
    GROUP BY product_id
) ls ON i.product_id = ls.product_id
JOIN products p ON i.product_id = p.product_id
CROSS JOIN (
    SELECT MAX(STR_TO_DATE(order_date, '%m/%d/%Y')) AS reference_date
    FROM sales
) md
WHERE 
    i.stock_quantity > 0
    AND DATEDIFF(md.reference_date, ls.last_sale_date) > 90;
    SELECT 
    SUM(i.stock_quantity * p.cost_price) AS total_inventory_value
FROM inventory i
JOIN products p 
    ON i.product_id = p.product_id;
    -- REGION WISE DEMAND
    SELECT 
    s.region,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.quantity * p.cost_price) AS total_sales_value
FROM sales s
JOIN products p 
    ON s.product_id = p.product_id
GROUP BY s.region
ORDER BY total_quantity_sold DESC;
SELECT 
    s.region,
    s.product_id,
    SUM(s.quantity) AS quantity_sold,
    SUM(s.quantity * p.cost_price) AS sales_value
FROM sales s
JOIN products p 
    ON s.product_id = p.product_id
GROUP BY s.region, s.product_id
ORDER BY s.region, quantity_sold DESC;
