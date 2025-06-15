use TreeBM;

-- ================================================
-- Add English comments to tables and columns
-- ================================================

-- Table comments
ALTER TABLE raw_materials
    COMMENT = 'Table of raw materials used in manufacturing processes';

ALTER TABLE products
    COMMENT = 'Table of finished products available for sale';

ALTER TABLE product_configurations
    COMMENT = 'Table of product variants with independent price and stock';

-- Column comments for raw_materials
ALTER TABLE raw_materials
    MODIFY id INT AUTO_INCREMENT
        COMMENT 'Primary key of raw_materials table',
    MODIFY name            VARCHAR(100)      NOT NULL
        COMMENT 'Name of the raw material',
    MODIFY description     TEXT
        COMMENT 'Detailed description of the raw material',
    MODIFY stock           INT NOT NULL DEFAULT 0
        COMMENT 'Available stock quantity';

-- Column comments for products
ALTER TABLE products
    MODIFY id      INT AUTO_INCREMENT
        COMMENT 'Primary key of products table',
    MODIFY name            VARCHAR(100)      NOT NULL
        COMMENT 'Name of the product',
    MODIFY description     TEXT
        COMMENT 'Detailed description of the product',
    MODIFY has_configurations  BOOL DEFAULT FALSE
        COMMENT 'Flag: has multiple configurations',
    MODIFY price           INT NOT NULL
        COMMENT 'Base price of the product',
    MODIFY stock           INT NOT NULL DEFAULT 0
        COMMENT 'Current stock quantity';

-- Column comments for product_configurations
ALTER TABLE product_configurations
    MODIFY id INT AUTO_INCREMENT
        COMMENT 'Primary key of product_configurations table',
    MODIFY product_id       INT NOT NULL
        COMMENT 'Foreign key to products.product_id',
    MODIFY name             VARCHAR(100)      NOT NULL
        COMMENT 'Configuration name',
    MODIFY price            INT NOT NULL
        COMMENT 'Price for this configuration',
    MODIFY stock            INT NOT NULL DEFAULT 0
        COMMENT 'Stock level of this configuration';


-- ================================================
-- Add business-rule constraints, unique keys, and indexes
-- ================================================

-- 1. Business rules via CHECK constraints
ALTER TABLE products
    ADD CONSTRAINT chk_products_price CHECK (price >= 0),
    ADD CONSTRAINT chk_products_stock CHECK (stock >= 0);

ALTER TABLE product_configurations
    ADD CONSTRAINT chk_cfg_price CHECK (price >= 0),
    ADD CONSTRAINT chk_cfg_stock CHECK (stock >= 0);

ALTER TABLE raw_materials
    ADD CONSTRAINT chk_rm_stock CHECK (stock >= 0);

-- 2. Unique keys to prevent duplicates
ALTER TABLE storage_fields
    ADD CONSTRAINT uk_storage_code UNIQUE (code);

ALTER TABLE clients
    ADD CONSTRAINT uk_clients_email UNIQUE (email),
    ADD CONSTRAINT uk_clients_phone UNIQUE (phone);

-- 3. Additional indexes for optimizing reports and JOINs
CREATE INDEX idx_orders_client_date ON orders           (client_id, order_date);
CREATE INDEX idx_order_items_order    ON order_items    (order_id);
CREATE INDEX idx_prod_items_config    ON product_items  (configuration_id);
