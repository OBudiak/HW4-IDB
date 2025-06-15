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

* **Count rows in all tables**: Use the query in `queries_and_triggers.sql`:

  ```sql
  SELECT table_name,
         table_rows
  FROM information_schema.tables
  WHERE table_schema = DATABASE();
  ```
* **Fetch client orders**: Retrieve a client’s full order history:

  ```sql
  CALL sp_get_orders_by_client(123);
  ```
* **Check product stock**: View current stock for a specific configuration:

  ```sql
  SELECT configuration_id,
         stock
    FROM product_configurations
   WHERE configuration_id = 456;
  ```
* **Process a new order**: Insert into `orders` and `order_items`. Built-in triggers will:

  1. Validate and deduct raw material and product stock
  2. Update the order total
  3. Maintain audit trails

  Example transaction:

  ```sql
  START TRANSACTION;
    INSERT INTO orders(client_id, order_date)
    VALUES (123, NOW());

    INSERT INTO order_items(
      order_id,
      configuration_id,
      quantity,
      unit_price
    ) VALUES (
      LAST_INSERT_ID(),
      789,
      5,
      100
    );
  COMMIT;
  ```

## 7. Data Insertion

> **Note:** Row counts were calculated manually after final setup using a `UNION ALL` query.

![Row counts in database](https://github.com/user-attachments/assets/6a6ddb2c-cce0-433e-b885-6691c7b4d673)
