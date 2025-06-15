# TreeBM – Business Management System

## 1. Overview

TreeBM is an operational database designed to manage the end-to-end lifecycle of products, from raw materials through manufacturing to sales and distribution. It supports inventory tracking, order processing, client management, and production workflows, providing a centralized, scalable backbone for business operations.

## 2. Business Understanding

**Domain**: Manufacturing and e-commerce of configurable products

**Problem statement**: Coordinate procurement of raw materials, manufacturing steps, inventory management across multiple warehouses, and order fulfillment while maintaining data consistency and performance at scale.

**Key entities**:

* **Raw Materials**: Fundamental inputs for production, tracked by stock levels.
* **Products & Configurations**: Finished goods and their variants, each with independent pricing and stock.
* **Storage Fields**: Physical warehouse locations for inventory batches.
* **Clients & Orders**: Customer profiles and their purchase history.
* **Manufacturing Items & Usage**: Links between production batches and consumed raw materials.

This model enables tracking of KPIs such as throughput, stock turnover, order fulfillment times, and top-selling configurations.

## 3. Schema Design & Relationships

* **One-to-many**: A single product → multiple configurations; a client → multiple orders; an order → multiple order items; a configuration → multiple inventory batches.
* **Many-to-many**: Manufacturing items consume multiple raw materials via the junction table `manufacturing_used_materials`.
* **Constraints & Integrity**:

  * `NOT NULL`, `UNIQUE`, `CHECK` on prices and stock (≥ 0)
  * `FOREIGN KEY` with `ON DELETE CASCADE` for referential integrity
  * Indexes on key columns (e.g., `orders(client_id, order_date)`) for performance

## 4. Entity-Relationship Diagram

![Entity-Relationship Diagram](https://github.com/user-attachments/assets/9140ab76-cbdf-43c1-9846-14f855eaacd4)

## 5. Implementation of Assignment Requirements

| Requirement                                       | Implementation                                             |
| ------------------------------------------------- | ---------------------------------------------------------- |
| Operational DB for chosen use case                | Full schema covering procurement → manufacturing → sales   |
| Entity relationships (1:1, 1\:m, m\:n)            | See Section 3                                              |
| Constraints: NOT NULL, UNIQUE, CHECK, FOREIGN KEY | Defined in DDL and `comments_and_indexes.sql`              |
| Indexes for optimization                          | Added key indexes in `comments_and_indexes.sql`            |
| Comments on tables and columns                    | All tables/columns commented in `comments_and_indexes.sql` |
| ERD presentation                                  | Section 4                                                  |
| Correct database terminology                      | Used consistently throughout documentation and code        |
| Business understanding                            | Section 2                                                  |
| **Additional Points**                             |                                                            |
| 3 users with different privileges                 | Defined in `queries_and_triggers.sql`                      |
| 1 view for reporting                              | `vw_order_summary` in `queries_and_triggers.sql`           |
| Stored procedure                                  | `sp_get_orders_by_client` in `queries_and_triggers.sql`    |
| Trigger/function                                  | Triggers on `order_items` before/after insert              |

## 6. Usage Examples

* **Count rows in all tables**: Execute the block in `queries_and_triggers.sql` to list all table row counts:

  ```sql
  SELECT 'raw_materials' AS `Table`, COUNT(*) AS `Rows` FROM raw_materials
  UNION ALL
  SELECT 'products',       COUNT(*) FROM products
  UNION ALL
  SELECT 'storage_fields', COUNT(*) FROM storage_fields
  UNION ALL
  SELECT 'clients',        COUNT(*) FROM clients
  UNION ALL
  SELECT 'product_configurations', COUNT(*) FROM product_configurations
  UNION ALL
  SELECT 'orders',         COUNT(*) FROM orders
  UNION ALL
  SELECT 'product_items',  COUNT(*) FROM product_items
  UNION ALL
  SELECT 'order_items',    COUNT(*) FROM order_items
  UNION ALL
  SELECT 'defected_products', COUNT(*) FROM defected_products
  UNION ALL
  SELECT 'manufacturing_items', COUNT(*) FROM manufacturing_items
  UNION ALL
  SELECT 'manufacturing_used_materials', COUNT(*) FROM manufacturing_used_materials
  ORDER BY `Table`;
  ```

* **Fetch client orders**: Call the stored procedure to get a client’s orders:

  ```sql
  CALL sp_get_orders_by_client(123);
  ```

* **Check configuration stock**: Query the current stock of a specific product configuration:

  ```sql
  SELECT
    id        AS configuration_id,
    stock
  FROM product_configurations
  WHERE id = 456;
  ```

* **Process a new order**:

  1. Insert a new order (initial `total_price` set to 0):

     ```sql
     START TRANSACTION;
       INSERT INTO orders(client_id, total_price, status)
       VALUES (123, 0, 'new');
       SET @order_id = LAST_INSERT_ID();
     ```
  2. Add items—leave `price_per_unit` NULL to let the trigger fetch the correct price:

     ```sql
     INSERT INTO order_items (
      order_id,
      configuration_id,
      price_per_unit,
      quantity
      )
     SELECT
      @order_id,
      pc.id,
      pc.price,
      5
     FROM product_configurations AS pc
     WHERE pc.id = 789;
     
     ```
  3. Commit and let triggers handle pricing, stock deduction, and order total update:

     ```sql
     COMMIT;
     ```

  **Note**: If you see a foreign key error like `Cannot add or update a child row... FOREIGN KEY (configuration_id) REFERENCES product_configurations(id)`, ensure that the `configuration_id` you insert exists in `product_configurations` (column `id`) and that you have created the related `orders` row first.


## 7. Data Insertion

> **Note:** Row counts were calculated manually after final setup using a `UNION ALL` query.

![Row counts in database](https://github.com/user-attachments/assets/6a6ddb2c-cce0-433e-b885-6691c7b4d673)
