USE TreeBM;

-- ==========================================================
--               Count rows in from all tables
-- ==========================================================

SELECT 'raw_materials'              AS `Таблиця`, COUNT(*) AS `Кількість рядків` FROM raw_materials
UNION ALL
SELECT 'products',                       COUNT(*) FROM products
UNION ALL
SELECT 'storage_fields',                COUNT(*) FROM storage_fields
UNION ALL
SELECT 'clients',                       COUNT(*) FROM clients
UNION ALL
SELECT 'product_configurations',        COUNT(*) FROM product_configurations
UNION ALL
SELECT 'orders',                        COUNT(*) FROM orders
UNION ALL
SELECT 'product_items',                 COUNT(*) FROM product_items
UNION ALL
SELECT 'order_items',                   COUNT(*) FROM order_items
UNION ALL
SELECT 'defected_products',             COUNT(*) FROM defected_products
UNION ALL
SELECT 'manufacturing_items',           COUNT(*) FROM manufacturing_items
UNION ALL
SELECT 'manufacturing_used_materials',  COUNT(*) FROM manufacturing_used_materials
ORDER BY `Таблиця`;


-- ==========================================================
--                      Adding users
-- ==========================================================

CREATE USER 'reader'@'%'    IDENTIFIED BY 'reader_pass';
GRANT SELECT                          ON TreeBM.* TO 'reader'@'%';

CREATE USER 'storage_manager'@'%'    IDENTIFIED BY 'storage_manager_pass';
GRANT SELECT, UPDATE                 ON TreeBM.* TO 'storage_manager'@'%';

CREATE USER 'manager'@'%'    IDENTIFIED BY 'writer_pass';
GRANT SELECT, INSERT, UPDATE, DELETE ON TreeBM.* TO 'writer'@'%';

CREATE USER 'analyst'@'%'   IDENTIFIED BY 'analyst_pass';
GRANT SELECT, SHOW VIEW             ON TreeBM.* TO 'analyst'@'%';


-- ==========================================================
--                 View for short reports
-- ==========================================================

CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.id                                 AS order_id,
    o.order_date,
    CONCAT(c.first_name, ' ', c.last_name) AS client_name,
    o.total_price
FROM orders o
         JOIN clients c ON o.client_id = c.id;


-- ==========================================================
--              Procedure for all client orders
-- ==========================================================
-- *returns all orders from client (id) with date, total price and status

DELIMITER //
CREATE PROCEDURE sp_get_orders_by_client(IN p_client_id INT)
BEGIN
    SELECT
        id,
        order_date,
        total_price,
        status
    FROM orders
    WHERE client_id = p_client_id;
END//
DELIMITER ;

CALL sp_get_orders_by_client(355);


-- ==========================================================
--               Triggers for stock updating
-- ==========================================================

DELIMITER //

-- 1. Before inserting into order_items, automatically set the unit price
CREATE TRIGGER trg_order_items_before_insert
    BEFORE INSERT ON order_items
    FOR EACH ROW
BEGIN
    IF NEW.price_per_unit IS NULL OR NEW.price_per_unit = 0 THEN
        SET NEW.price_per_unit = (
            SELECT price
            FROM product_configurations
            WHERE id = NEW.configuration_id
        );
    END IF;
END;//

-- 2. After inserting into order_items, deduct stock and update total_price
CREATE TRIGGER trg_order_items_after_insert
    AFTER INSERT ON order_items
    FOR EACH ROW
BEGIN
    -- 2.1 Deduct from configuration stock
    UPDATE product_configurations
    SET stock = stock - NEW.quantity
    WHERE id = NEW.configuration_id;

    -- 2.2 Deduct from the overall product stock
    UPDATE products p
        JOIN product_configurations pc ON p.id = pc.product_id
    SET p.stock = p.stock - NEW.quantity
    WHERE pc.id = NEW.configuration_id;

    -- 2.3 Deduct from the earliest inventory batch (FIFO)
    UPDATE product_items pi
        JOIN (
            -- select the first available batch with sufficient stock
            SELECT id
            FROM product_items
            WHERE configuration_id = NEW.configuration_id
              AND stock >= NEW.quantity
            ORDER BY created_at
            LIMIT 1
        ) AS sub ON pi.id = sub.id
    SET pi.stock = pi.stock - NEW.quantity;

    -- 2.4 Update the order's total_price
    UPDATE orders
    SET total_price = total_price + (NEW.price_per_unit * NEW.quantity)
    WHERE id = NEW.order_id;
END;//

DELIMITER ;



