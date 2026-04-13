CREATE DATABASE benchmark;
USE benchmark;
CREATE TABLE fact (id INT(4), dim1_id INT(4), dim2_id INT(4), dim3_id INT(4), dim4_id INT(4), dim5_id INT(4), dim6_id INT(4), dim7_id INT(4), dim8_id INT(4));
CREATE TABLE dim1 (id INT(4), val INT(4));
CREATE TABLE dim2 (id INT(4), val INT(4));
CREATE TABLE dim3 (id INT(4), val INT(4));
CREATE TABLE dim4 (id INT(4), val INT(4));
CREATE TABLE dim5 (id INT(4), val INT(4));
CREATE TABLE dim6 (id INT(4), val INT(4));
CREATE TABLE dim7 (id INT(4), val INT(4));
CREATE TABLE dim8 (id INT(4), val INT(4));
INSERT INTO fact VALUES (1, 1, 1, 1, 1, 1, 1, 1, 1);
INSERT INTO dim1 VALUES (1, 100);
INSERT INTO dim2 VALUES (1, 100);
INSERT INTO dim3 VALUES (1, 100);
INSERT INTO dim4 VALUES (1, 100);
INSERT INTO dim5 VALUES (1, 100);
INSERT INTO dim6 VALUES (1, 100);
INSERT INTO dim7 VALUES (1, 100);
INSERT INTO dim8 VALUES (1, 100);
SELECT fact.id, dim1.val, dim2.val, dim3.val, dim4.val, dim5.val, dim6.val, dim7.val, dim8.val
FROM fact, dim1, dim2, dim3, dim4, dim5, dim6, dim7, dim8
WHERE fact.dim1_id = dim1.id AND fact.dim2_id = dim2.id AND fact.dim3_id = dim3.id AND fact.dim4_id = dim4.id AND fact.dim5_id = dim5.id AND fact.dim6_id = dim6.id AND fact.dim7_id = dim7.id AND fact.dim8_id = dim8.id;
