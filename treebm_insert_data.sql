-- ========================================
-- 0. ПАРАМЕТРИ
-- ========================================
SET @RAW_MATERIALS           = 50;      -- raw_materials
SET @PRODUCTS                = 100;     -- products
SET @STORAGE_FIELDS          = 10;      -- storage_fields
SET @PRODUCT_ITEMS           = 200000;  -- product_items
SET @CLIENTS                 = 20000;   -- clients
SET @ORDERS                  = 500000;   -- orders
SET @MAX_ITEMS_PER_ORDER     = 4;       -- max позицій в одному замовленні
SET @MAX_MATERIALS_PER_MANUF = 3;       -- max матеріалів на одне manufacturing_item

-- ========================================
-- 1. Seed raw_materials
-- ========================================
DROP PROCEDURE IF EXISTS seed_raw_materials;
DELIMITER //
CREATE PROCEDURE seed_raw_materials(IN cnt INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= cnt DO
            INSERT INTO raw_materials(name,description,stock)
            VALUES(
                      CONCAT('Material ', i),
                      CONCAT('Description for material ', i),
                      FLOOR(RAND()*1000)
                  );
            SET i = i + 1;
        END WHILE;
END;
//
DELIMITER ;
CALL seed_raw_materials(@RAW_MATERIALS);

-- ========================================
-- 2. Seed products
-- ========================================
DROP PROCEDURE IF EXISTS seed_products;
DELIMITER //
CREATE PROCEDURE seed_products(IN cnt INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= cnt DO
            INSERT INTO products(name,description,has_configurations,price,stock)
            VALUES(
                      CONCAT('Product ', i),
                      CONCAT('Auto-generated product ', i),
                      1,
                      ROUND(10 + RAND()*90,2),
                      FLOOR(RAND()*500)
                  );
            SET i = i + 1;
        END WHILE;
END;
//
DELIMITER ;
CALL seed_products(@PRODUCTS);

-- ========================================
-- 3. Seed product_configurations
-- ========================================
DROP PROCEDURE IF EXISTS seed_product_configurations;
DELIMITER //
CREATE PROCEDURE seed_product_configurations()
BEGIN
    DECLARE done     INT DEFAULT FALSE;
    DECLARE pid      INT;
    DECLARE cfg_cnt  INT;
    DECLARE j        INT;
    DECLARE cur CURSOR FOR SELECT id FROM products;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO pid;
        IF done THEN LEAVE read_loop; END IF;

        SET cfg_cnt = FLOOR(1 + RAND()*3);
        SET j = 1;
        WHILE j <= cfg_cnt DO
                INSERT INTO product_configurations(product_id,name,is_main,price,stock)
                VALUES(
                          pid,
                          CONCAT('Config ', j),
                          IF(j=1,1,0),
                          ROUND(5 + RAND()*95,2),
                          FLOOR(RAND()*500)
                      );
                SET j = j + 1;
            END WHILE;
    END LOOP;
    CLOSE cur;
END;
//
DELIMITER ;
CALL seed_product_configurations();

-- ========================================
-- 4. Seed storage_fields
-- ========================================
INSERT INTO storage_fields(code, name, address)
SELECT
    CONCAT('WH-', LPAD(n,2,'0')),
    CONCAT('Warehouse ', n),
    CONCAT('Address ', n)
FROM (
         SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
     ) AS seq
WHERE n <= @STORAGE_FIELDS;

-- ========================================
-- 5. Seed product_items
-- ========================================
DROP PROCEDURE IF EXISTS seed_product_items;
DELIMITER //
CREATE PROCEDURE seed_product_items(IN cnt INT)
BEGIN
    DECLARE i       INT DEFAULT 1;
    DECLARE min_pc  INT; DECLARE max_pc INT;
    DECLARE min_sf  INT; DECLARE max_sf INT;
    DECLARE pcid    INT; DECLARE sfid    INT;

    SELECT MIN(id), MAX(id) INTO min_pc, max_pc FROM product_configurations;
    SELECT MIN(id), MAX(id) INTO min_sf, max_sf FROM storage_fields;

    WHILE i <= cnt DO
            SET pcid = FLOOR(min_pc + RAND()*(max_pc-min_pc+1));
            SET sfid = FLOOR(min_sf + RAND()*(max_sf-min_sf+1));
            INSERT INTO product_items(configuration_id,storage_field_id,description,stock)
            VALUES(
                      pcid,
                      sfid,
                      CONCAT('Batch for config ', pcid, ' @WH-', sfid),
                      FLOOR(RAND()*200)
                  );
            SET i = i + 1;
        END WHILE;
END;
//
DELIMITER ;
CALL seed_product_items(@PRODUCT_ITEMS);

-- ========================================
-- 6. Seed clients
-- ========================================
DROP PROCEDURE IF EXISTS seed_clients;
DELIMITER //
CREATE PROCEDURE seed_clients(IN cnt INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= cnt DO
            INSERT INTO clients(first_name,last_name,description,phone,email)
            VALUES(
                      CONCAT('ClientFN', i),
                      CONCAT('ClientLN', i),
                      CONCAT('Client description ', i),
                      CONCAT('+380', FLOOR(100000000 + RAND()*899999999)),
                      CONCAT('client', i, '@example.com')
                  );
            SET i = i + 1;
        END WHILE;
END;
//
DELIMITER ;
CALL seed_clients(@CLIENTS);

-- ========================================
-- 7. Seed orders + order_items
-- ========================================
DROP PROCEDURE IF EXISTS seed_orders;
DELIMITER //
CREATE PROCEDURE seed_orders(IN cnt INT, IN max_items INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE oid INT;
    DECLARE items_cnt INT;
    DECLARE j INT;
    DECLARE client_cnt INT;
    DECLARE min_cfg INT;
    DECLARE max_cfg INT;
    SELECT COUNT(*) INTO client_cnt FROM clients;
    SELECT MIN(id), MAX(id) INTO min_cfg, max_cfg FROM product_configurations;
    SET autocommit = 0;
    WHILE i <= cnt DO
            INSERT INTO orders(client_id,total_price,status)
            VALUES(FLOOR(1 + RAND()*client_cnt),0,'new');
            SET oid = LAST_INSERT_ID();
            SET items_cnt = FLOOR(1 + RAND()*max_items);
            SET j = 1;
            WHILE j <= items_cnt DO
                    INSERT INTO order_items(order_id,configuration_id,price_per_unit,quantity)
                    VALUES(
                              oid,
                              FLOOR(min_cfg + RAND()*(max_cfg-min_cfg+1)),
                              ROUND(5 + RAND()*95,2),
                              FLOOR(1 + RAND()*10)
                          );
                    SET j = j + 1;
                END WHILE;
            UPDATE orders o
                JOIN (
                    SELECT order_id, SUM(price_per_unit * quantity) AS tp
                    FROM order_items
                    WHERE order_id = oid
                    GROUP BY order_id
                ) sub ON o.id = sub.order_id
            SET o.total_price = sub.tp
            WHERE o.id = oid;
            IF MOD(i,1000)=0 THEN
                COMMIT;
                SELECT CONCAT('Inserted ',i,' orders so far') AS progress;
            END IF;
            SET i = i + 1;
        END WHILE;
    COMMIT;
    SET autocommit = 1;
END;
//
DELIMITER ;
CALL seed_orders(@ORDERS, @MAX_ITEMS_PER_ORDER);


# SET FOREIGN_KEY_CHECKS = 0;
# TRUNCATE TABLE orders;
# TRUNCATE TABLE order_items;
# SET FOREIGN_KEY_CHECKS = 1;


# SELECT COUNT(*) AS clients_cnt FROM clients;
# SELECT COUNT(*) AS cfg_cnt     FROM product_configurations;

-- ========================================
-- 8. Seed manufacturing_items
-- ========================================
INSERT INTO manufacturing_items(product_item_id,description,status,count)
SELECT
    pi.id,
    CONCAT('Manufacture for batch ', pi.id),
    ELT(FLOOR(1+RAND()*3),'new','producing','made'),
    FLOOR(1 + RAND()*10)
FROM product_items pi;

-- ========================================
-- 9. Seed manufacturing_used_materials
-- ========================================
INSERT INTO manufacturing_used_materials(manufacturing_item_id, raw_material_id, count)
SELECT
    mi.id,
    FLOOR(1 + RAND()*@RAW_MATERIALS),
    FLOOR(1 + RAND()*@MAX_MATERIALS_PER_MANUF)
FROM manufacturing_items mi
         CROSS JOIN (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
) AS nums
WHERE nums.n <= FLOOR(1 + RAND()*@MAX_MATERIALS_PER_MANUF)
ON DUPLICATE KEY UPDATE
    count = VALUES(count);

-- ========================================
-- 10. Seed defected_products (~10% of manufacturing_items)
-- ========================================
INSERT INTO defected_products(product_item_id,description,losses,count)
SELECT
    mi.product_item_id,
    CONCAT('Defect for manuf ', mi.id),
    ROUND(RAND()*10,2),
    FLOOR(RAND()*mi.count)
FROM manufacturing_items mi
WHERE RAND() < 0.1;
