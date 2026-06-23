-- All services use the default 'retailstore' database created by RDS
-- This script only creates service tables

CREATE TABLE IF NOT EXISTS cart_items (
    customer_id VARCHAR(255) NOT NULL,
    item_id     VARCHAR(255) NOT NULL,
    quantity    INTEGER      NOT NULL,
    unit_price  INTEGER      NOT NULL,
    PRIMARY KEY (customer_id, item_id)
);
