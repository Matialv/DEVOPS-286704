-- The 'orders' database is created by POSTGRES_DB env var
-- This script creates catalogdb, cartdb and grants permissions

CREATE DATABASE catalogdb;
CREATE DATABASE cartdb;

GRANT ALL PRIVILEGES ON DATABASE catalogdb TO retailstore;
GRANT ALL PRIVILEGES ON DATABASE cartdb TO retailstore;
GRANT ALL PRIVILEGES ON DATABASE orders TO retailstore;

\c orders
GRANT ALL ON SCHEMA public TO retailstore;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO retailstore;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO retailstore;

\c catalogdb
GRANT ALL ON SCHEMA public TO retailstore;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO retailstore;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO retailstore;

\c cartdb
GRANT ALL ON SCHEMA public TO retailstore;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO retailstore;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO retailstore;

CREATE TABLE cart_items (
    customer_id VARCHAR(255) NOT NULL,
    item_id     VARCHAR(255) NOT NULL,
    quantity    INTEGER      NOT NULL,
    unit_price  INTEGER      NOT NULL,
    PRIMARY KEY (customer_id, item_id)
);
