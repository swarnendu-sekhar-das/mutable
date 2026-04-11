-- Demo: TwoPhaseOptimizer join ordering on a 5-way join
CREATE DATABASE shop;
USE shop;

-- Schema
CREATE TABLE customers  ( id INT(4) NOT NULL, name CHAR(20) NOT NULL );
CREATE TABLE orders     ( id INT(4) NOT NULL, cid INT(4) NOT NULL, total INT(4) NOT NULL );
CREATE TABLE items      ( id INT(4) NOT NULL, oid INT(4) NOT NULL, pid INT(4) NOT NULL, qty INT(4) NOT NULL );
CREATE TABLE products   ( id INT(4) NOT NULL, price INT(4) NOT NULL );
CREATE TABLE reviews    ( id INT(4) NOT NULL, pid INT(4) NOT NULL, score INT(4) NOT NULL );

-- Data
INSERT INTO customers VALUES (1, "Alice"), (2, "Bob"), (3, "Carol"), (4, "Dave"), (5, "Eve");
INSERT INTO orders VALUES (1, 1, 100), (2, 1, 200), (3, 2, 150), (4, 3, 300), (5, 4, 50);
INSERT INTO items VALUES (1, 1, 1, 2), (2, 1, 2, 1), (3, 2, 3, 4), (4, 3, 1, 1), (5, 4, 2, 3), (6, 5, 3, 2);
INSERT INTO products VALUES (1, 25), (2, 50), (3, 75);
INSERT INTO reviews VALUES (1, 1, 5), (2, 2, 4), (3, 3, 3), (4, 1, 4), (5, 2, 5);

-- 5-way join: customers -> orders -> items -> products -> reviews
SELECT customers.name, orders.total, items.qty, products.price, reviews.score
FROM customers, orders, items, products, reviews
WHERE customers.id = orders.cid
  AND orders.id = items.oid
  AND items.pid = products.id
  AND products.id = reviews.pid;
