# TreeBM – Business Management System

## 1. Overview

TreeBM is an operational database designed to manage the end-to-end lifecycle of products, from raw materials through manufacturing to sales and distribution. It supports inventory tracking, order processing, client management and production workflows, providing a centralized, scalable backbone for business operations.

## 2. Business Understanding

**Domain**: Manufacturing and e-commerce of configurable products

**Problem statement**: Coordinate procurement of raw materials, manufacturing steps, inventory management across multiple warehouses, and order fulfillment while maintaining data consistency and performance at scale.

**Key entities**:

* **Raw Materials**: fundamental inputs for production, tracked by stock levels.
* **Products & Configurations**: finished goods and their variants, with independent pricing and stock.
* **Storage Fields**: physical warehouse locations for batches.
* **Clients & Orders**: customer information and their purchase history.
* **Manufacturing Items & Usage**: linkage between produced batches and consumed raw materials.

This model enables tracking KPIs such as throughput, stock turnover, order fulfillment times, and top-selling configurations.

## 3. Schema Design & Relationships

* **One-to-many**: A single product → multiple configurations; a client → multiple orders; an order → multiple order items; a configuration → multiple inventory batches.
* **Many-to-many**: Manufacturing items consume multiple raw materials via a junction table `manufacturing_used_materials`.
* **Constraints & Integrity**:

  * `NOT NULL`, `UNIQUE`, `CHECK` on prices and stock ≥ 0
  * `FOREIGN KEY` with `ON DELETE CASCADE` for referential integrity
  * Indexes on join and filter columns for performance (e.g., `orders(client_id, order_date)`).

## 4. Entity-Relationship Diagram

![tree_bm](https://github.com/user-attachments/assets/9140ab76-cbdf-43c1-9846-14f855eaacd4)


## 5. Implementation of Assignment Requirements

| Requirement                                       | Implementation                                             |
| ------------------------------------------------- | ---------------------------------------------------------- |
| Operational DB for chosen use case                | Full schema covering procurement → manufacturing → sales   |
| Entity relationships (1:1, 1\:m, m\:n)            | See Section 3                                              |
| Constraints: NOT NULL, UNIQUE, CHECK, FOREIGN KEY | Defined in DDL and via `comments_and_indexes.sql`          |
| Indexes for optimization                          | Added key indexes in `comments_and_indexes.sql`            |
| Comments on tables and columns                    | All tables/columns commented in `comments_and_indexes.sql` |
| ERD presentation                                  | Reference in Section 4                                     |
| Correct database terminology in documentation     | Throughout README and code comments                        |
| Business understanding                            | Detailed in Section 2                                      |
| **Additional Points**                             |                                                            |
| 3 users with different privileges                 | Created in `queries_and_triggers.sql`                      |
| 1 view for reporting                              | `vw_order_summary` in `queries_and_triggers.sql`           |
| Stored procedure                                  | `sp_get_orders_by_client` in `queries_and_triggers.sql`    |
| Trigger/function                                  | Triggers on `order_items` before/after insert              |

## 6. Usage Examples

* **Count rows in all tables**: Use the provided query in `queries_and_triggers.sql` to iterate over `information_schema.tables` and return row counts per table:

  ```sql
  SELECT table_name,
         table_rows
  FROM information_schema.tables
  WHERE table_schema = DATABASE();
  ```
* **Fetch client orders**: Retrieve an individual client’s full order history, including items:

  ```sql
  CALL sp_get_orders_by_client(123);
  ```
* **Check product stock**: Verify current stock for a specific product configuration:

  ```sql
  SELECT configuration_id, stock
  FROM product_configurations
  WHERE configuration_id = 456;
  ```
* **Process a new order**: Insert into `orders` and `order_items`; built-in triggers will:

  1. Validate and deduct raw material and product stock
  2. Update the order total
  3. Maintain audit trails
     Example transaction:

  ```sql
  START TRANSACTION;
    INSERT INTO orders(client_id, order_date) VALUES (123, NOW());
    INSERT INTO order_items(order_id, configuration_id, quantity, unit_price)
    VALUES (LAST_INSERT_ID(), 789, 5, 100);
  COMMIT;
  ```

## 7. Data insertion

**Note:** The count of rows differs from the parameters in settings because it was calculated manually after all debugging and setup were completed, using a UNION ALL. 

![Кількість рядків в базі даних](https://github.com/user-attachments/assets/6a6ddb2c-cce0-433e-b885-6691c7b4d673)
