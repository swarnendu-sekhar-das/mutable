CREATE OR REPLACE FUNCTION insert_suite(text)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO "Suites" (name)
    SELECT $1
    WHERE NOT $1 IN (SELECT name FROM "Suites")
$func$;

CREATE OR REPLACE FUNCTION insert_benchmark(int, text)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO "Benchmarks" (suite, name)
    SELECT $1, $2
    WHERE NOT ($1, $2) IN (SELECT suite, name FROM "Benchmarks");
$func$;

CREATE OR REPLACE FUNCTION insert_configuration(text, text)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO "Configurations" (name, parameters)
    SELECT $1, $2
    WHERE NOT ($1, $2) IN (SELECT name, parameters FROM "Configurations");
$func$;

CREATE OR REPLACE FUNCTION insert_timestamp(text, timestamptz, text)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO "Timestamps" ("commit", "timestamp", "host")
    SELECT $1, $2, $3
    WHERE NOT ($2, $3) IN (SELECT timestamp, host FROM "Timestamps");
$func$;

CREATE OR REPLACE FUNCTION insert_experiment(int, text, int, text, bool, int)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO "Experiments" (benchmark, name, version, description, is_read_only, chart_config)
    SELECT $1, $2, $3, $4, $5, $6
    WHERE NOT ($1, $2, $3) IN (SELECT benchmark, name, version FROM "Experiments");
$func$;

CREATE OR REPLACE FUNCTION insert_chartconfig(text, text, text, text, text, text)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO "ChartConfig" (scale_x, scale_y, type_x, type_y, label_x, label_y)
    SELECT $1, $2, $3, $4, $5, $6
    WHERE NOT ($1, $2, $3, $4, $5, $6) IN (SELECT scale_x, scale_y, type_x, type_y, label_x, label_y FROM "ChartConfig");
$func$;

DO $$
DECLARE
    timestamp_id integer;
    suite_id integer;
    benchmark_id integer;
    experiment_id integer;
    configuration_id integer;
    chartconfig_id integer;
BEGIN
    -- Get timestamp
    PERFORM insert_timestamp('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local');
    SELECT id FROM "Timestamps"
    WHERE "commit"='6504d630fae4ae96d3e65779747ecbeb3938a08a'
      AND "timestamp"='2026-04-14 03:26:12'
      AND "host"='Swarnendus-MacBook-Air.local'
    INTO timestamp_id;

    -- Get suite
    PERFORM insert_suite('plan-enumerators');
    SELECT id FROM "Suites"
    WHERE name='plan-enumerators'
    INTO suite_id;

    -- Get benchmark
    PERFORM insert_benchmark(suite_id, 'cardinality-agnostic');
    SELECT id FROM "Benchmarks"
    WHERE suite=suite_id
      AND name='cardinality-agnostic'
    INTO benchmark_id;

    -- Get chart configuration
    PERFORM insert_chartconfig('linear', 'log', 'O', 'Q', 'Number of relations', 'Optimization time (ms)');
    SELECT id FROM "ChartConfig"
    WHERE scale_x='linear' AND scale_y='log'
      AND type_x='O' AND type_y='Q'
      AND label_x='Number of relations' AND label_y='Optimization time (ms)'
    INTO chartconfig_id;

    -- Get experiment
    PERFORM insert_experiment(benchmark_id, 'chain', 1, 'Plan enumeration of chain queries with methods that are agnostic to cardinalities.', TRUE, chartconfig_id);
    SELECT id FROM "Experiments"
    WHERE benchmark=benchmark_id
      AND name='chain'
      AND version=1
    INTO experiment_id;

    -- Update chartconfig of this experiment (if a new one was inserted)
    UPDATE "Experiments"
    SET chart_config=chartconfig_id
    WHERE id=experiment_id;

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPccp)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPccp)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'chain'
    --  config:     'mutable (single core, DPccp)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.08, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.034, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.018, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.029, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.019, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.055, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.04, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.041, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.029, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.064, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.048, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.041, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.083, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.068, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.071, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.082, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.061, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.184, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.188, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.13, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.166, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.128, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.22, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.257, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.202, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.212, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.208, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.345, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.319, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.291, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.329, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.293, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 0.77, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 0.773, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 0.782, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 0.717, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 0.722, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 1.089, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 0.771, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 0.703, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 0.706, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 0.691, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 0.974, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 0.935, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 1.192, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 0.917, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 0.87, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsizeOpt)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsizeOpt)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'chain'
    --  config:     'mutable (single core, DPsizeOpt)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.122, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.027, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.028, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.029, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.045, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.042, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.037, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.036, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.06, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.048, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.051, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.085, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.054, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.057, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.059, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.059, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.184, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.148, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.164, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.144, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.143, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.445, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.356, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.382, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.356, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.367, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 1.382, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 1.357, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 1.343, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 1.396, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 1.343, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 15.275, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 15.446, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 14.972, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 14.965, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 15.186, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 397.494, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 402.451, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 446.227, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 393.142, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 393.108, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 2016.87, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 2063.88, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 2034.97, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 2062.1, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 1992.56, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsub)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsub)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'chain'
    --  config:     'mutable (single core, DPsub)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.072, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.038, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.033, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.049, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.033, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.034, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.029, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.039, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.038, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.045, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.07, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.053, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.051, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.057, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.069, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.161, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.113, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.116, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.128, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.118, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.191, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.182, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.175, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.197, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.2, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.298, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.3, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.299, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.303, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.294, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 1.21, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 1.009, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 1.045, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 1.002, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 1.107, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 16.235, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 15.145, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 15.306, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 15.56, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 15.153, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 72.469, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 61.022, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 58.762, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 58.453, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 58.403, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsubOpt)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsubOpt)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'chain'
    --  config:     'mutable (single core, DPsubOpt)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.087, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.025, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.057, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.053, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.039, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.033, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.038, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.039, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.041, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.073, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.053, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.05, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.056, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.055, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.15, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.122, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.115, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.106, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.11, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.201, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.224, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.172, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.171, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.166, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.292, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.324, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.275, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.268, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.265, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 0.87, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 0.932, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 1.189, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 0.855, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 0.912, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 8.145, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 8.212, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 8.526, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 8.618, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 8.755, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 32.207, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 33.295, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 31.803, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 31.737, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 32.032, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsizeSub)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsizeSub)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'chain'
    --  config:     'mutable (single core, DPsizeSub)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.079, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.022, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.029, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.027, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.046, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.033, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.042, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.036, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.053, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.055, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.08, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.054, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.053, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.074, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.069, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.168, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.112, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.218, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.117, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.12, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.221, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.186, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.195, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.194, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.217, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.337, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.324, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.316, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.312, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.423, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 1.228, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 1.069, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 1.18, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 1.169, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 1.386, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 16.517, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 16.807, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 17.002, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 19.464, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 17.763, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 64.662, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 67.078, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 69.308, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 67.405, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 69.247, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TDbasic)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TDbasic)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'chain'
    --  config:     'mutable (single core, TDbasic)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.071, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.037, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.022, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.048, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.039, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.035, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.054, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.045, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.04, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.046, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.04, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.07, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.056, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.053, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.052, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.059, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.145, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.114, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.116, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.108, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.123, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.195, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.182, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.177, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.184, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.175, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.283, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.286, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.276, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.332, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.271, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 0.877, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 0.892, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 0.907, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 0.852, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 0.865, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 2.789, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 2.642, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 2.548, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 2.919, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 2.973, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 9.822, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 9.513, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 9.707, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 9.083, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 9.502, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TDMinCutAGaT)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TDMinCutAGaT)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'chain'
    --  config:     'mutable (single core, TDMinCutAGaT)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.086, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.017, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.02, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.056, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.033, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.029, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.056, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.041, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.039, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.367, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.085, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.054, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.054, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.055, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.239, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.187, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.126, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.157, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.111, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.174, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.377, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.187, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.186, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.175, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.202, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.32, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.274, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.293, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.282, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.481, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 0.93, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 0.677, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 0.784, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 0.7, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 1.079, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 0.88, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 0.701, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 0.677, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 0.642, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 0.775, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 0.829, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 1.035, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 0.801, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 0.801, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 0.839, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TwoPhaseOptimizer)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TwoPhaseOptimizer)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'chain'
    --  config:     'mutable (single core, TwoPhaseOptimizer)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 3.307, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 6.805, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 3.114, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 3.219, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 3.614, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 8.95, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 11.026, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 8.416, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 8.349, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 9.704, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 13.072, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 13.885, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 13.406, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 13.168, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 13.452, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 19.892, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 19.281, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 17.142, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 18.313, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 19.625, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 42.815, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 43.788, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 34.038, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 32.712, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 33.631, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 47.624, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 50.514, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 43.466, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 44.951, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 47.882, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 60.206, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 67.597, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 57.843, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 57.313, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 61.982, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 76.516, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 82.959, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 75.563, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 78.677, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 78.711, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 143.919, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 114.941, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 100.697, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 108.281, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 106.416, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 170.605, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 125.803, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 124.956, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 166.171, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 121.419, 4);

    -- Get chart configuration
    PERFORM insert_chartconfig('linear', 'log', 'O', 'Q', 'Number of relations', 'Optimization time (ms)');
    SELECT id FROM "ChartConfig"
    WHERE scale_x='linear' AND scale_y='log'
      AND type_x='O' AND type_y='Q'
      AND label_x='Number of relations' AND label_y='Optimization time (ms)'
    INTO chartconfig_id;

    -- Get experiment
    PERFORM insert_experiment(benchmark_id, 'clique', 1, 'Plan enumeration of clique queries with methods that are agnostic to cardinalities.', TRUE, chartconfig_id);
    SELECT id FROM "Experiments"
    WHERE benchmark=benchmark_id
      AND name='clique'
      AND version=1
    INTO experiment_id;

    -- Update chartconfig of this experiment (if a new one was inserted)
    UPDATE "Experiments"
    SET chart_config=chartconfig_id
    WHERE id=experiment_id;

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPccp)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPccp)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'clique'
    --  config:     'mutable (single core, DPccp)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.09, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.029, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.065, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.044, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.038, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.046, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.038, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.07, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.058, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.056, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.073, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.061, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.125, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.106, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.104, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.11, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.122, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.691, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.701, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.641, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.764, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.657, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 3.977, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 3.747, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 3.95, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 3.794, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 3.704, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 28.43, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 28.294, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 28.138, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 28.325, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 28.361, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsizeOpt)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsizeOpt)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'clique'
    --  config:     'mutable (single core, DPsizeOpt)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.071, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.025, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.022, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.03, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.053, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.042, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.036, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.104, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.055, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.051, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.044, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.059, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.098, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.074, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.076, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.096, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.091, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.444, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.387, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.385, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.392, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.403, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 3.196, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 3.033, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 3.051, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 3.058, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 3.067, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 37.889, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 37.825, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 38.011, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 37.941, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 37.765, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsub)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsub)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'clique'
    --  config:     'mutable (single core, DPsub)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.086, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.02, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.022, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.021, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.019, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.051, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.04, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.027, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.055, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.051, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.045, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.093, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.074, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.071, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.096, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.079, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.769, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.352, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.349, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.346, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.421, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 2.031, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 2.092, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 2.011, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 2.031, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 2.089, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 16.149, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 16.388, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 16.422, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 16.204, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 16.364, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsubOpt)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsubOpt)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'clique'
    --  config:     'mutable (single core, DPsubOpt)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.071, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.021, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.022, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.015, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.019, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.061, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.027, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.028, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.055, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.06, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.044, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.046, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.085, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.069, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.077, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.08, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.076, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.299, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.267, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.275, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.256, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.263, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 1.18, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 1.18, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 1.17, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 1.238, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 1.186, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 8.528, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 8.736, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 8.319, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 8.653, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 8.405, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsizeSub)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsizeSub)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'clique'
    --  config:     'mutable (single core, DPsizeSub)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.107, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.028, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.017, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.018, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.046, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.047, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.031, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.031, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.063, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.059, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.042, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.112, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.079, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.072, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.09, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.113, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.411, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.383, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.342, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.349, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.379, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 2.045, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 1.988, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 2.113, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 2.004, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 2.057, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 16.115, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 16.108, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 16.334, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 16.364, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 16.355, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TDbasic)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TDbasic)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'clique'
    --  config:     'mutable (single core, TDbasic)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.073, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.02, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.022, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.051, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.033, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.034, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.029, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.059, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.046, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.046, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.095, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.08, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.075, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.091, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.079, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.368, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.32, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.352, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.315, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.337, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 1.758, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 1.922, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 1.762, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 1.732, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 1.725, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 14.074, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 13.678, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 13.868, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 13.856, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 13.707, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TDMinCutAGaT)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TDMinCutAGaT)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'clique'
    --  config:     'mutable (single core, TDMinCutAGaT)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.077, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.02, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.019, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.053, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.031, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.031, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.036, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.063, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.051, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.06, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.069, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.103, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.093, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.083, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.094, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.098, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.622, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.567, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.603, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.882, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.61, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 3.739, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 3.802, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 3.788, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 3.835, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 3.895, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 30.479, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 30.429, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 30.678, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 30.713, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 30.734, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TwoPhaseOptimizer)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TwoPhaseOptimizer)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'clique'
    --  config:     'mutable (single core, TwoPhaseOptimizer)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 3.213, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 3.315, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 3.195, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 6.812, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 3.3, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 8.229, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 8.379, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 8.096, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 7.942, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 8.029, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 13.204, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 13.116, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 13.879, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 12.679, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 12.669, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 16.785, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 16.96, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 16.693, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 16.408, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 16.373, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 33.171, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 33.33, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 38.026, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 36.915, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 36.194, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 44.527, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 45.065, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 47.598, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 46.395, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 47.428, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 56.495, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 57.436, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 60.634, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 61.94, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 62.484, 4);

    -- Get chart configuration
    PERFORM insert_chartconfig('linear', 'log', 'O', 'Q', 'Number of relations', 'Optimization time (ms)');
    SELECT id FROM "ChartConfig"
    WHERE scale_x='linear' AND scale_y='log'
      AND type_x='O' AND type_y='Q'
      AND label_x='Number of relations' AND label_y='Optimization time (ms)'
    INTO chartconfig_id;

    -- Get experiment
    PERFORM insert_experiment(benchmark_id, 'cycle', 1, 'Plan enumeration of cycle queries with methods that are agnostic to cardinalities.', TRUE, chartconfig_id);
    SELECT id FROM "Experiments"
    WHERE benchmark=benchmark_id
      AND name='cycle'
      AND version=1
    INTO experiment_id;

    -- Update chartconfig of this experiment (if a new one was inserted)
    UPDATE "Experiments"
    SET chart_config=chartconfig_id
    WHERE id=experiment_id;

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPccp)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPccp)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'cycle'
    --  config:     'mutable (single core, DPccp)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.085, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.022, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.016, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.017, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.06, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.037, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.034, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.038, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.034, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.062, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.051, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.104, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.084, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.069, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.072, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.069, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.202, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.17, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.162, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.162, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.159, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.277, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.258, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.257, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.263, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.257, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.473, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.394, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.418, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.389, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.421, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 1.069, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 0.951, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 0.966, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 0.902, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 0.928, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 1.34, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 1.198, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 1.464, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 1.199, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 1.289, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 1.579, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 1.551, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 1.646, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 1.529, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 1.606, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsizeOpt)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsizeOpt)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'cycle'
    --  config:     'mutable (single core, DPsizeOpt)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.077, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.029, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.032, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.032, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.029, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.051, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.031, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.048, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.042, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.043, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.054, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.053, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.076, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.079, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.076, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.065, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.063, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.209, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.198, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.175, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.158, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.159, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.419, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.421, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.437, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.408, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.402, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 1.598, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 1.564, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 1.589, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 1.608, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 1.585, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 17.729, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 17.804, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 17.484, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 17.782, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 18.232, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 559.992, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 580.558, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 566.84, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 578.619, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 564.363, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 3092.95, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 2990.05, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 3040.38, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 3312.92, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 3029.97, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsub)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsub)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'cycle'
    --  config:     'mutable (single core, DPsub)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.104, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.034, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.029, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.073, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.038, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.05, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.039, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.038, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.061, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.078, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.069, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.069, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.061, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.062, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.2, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.14, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.141, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.134, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.133, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.229, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.223, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.223, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.232, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.229, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.422, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.413, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.417, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.425, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.416, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 1.901, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 2.166, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 1.894, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 2.277, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 1.873, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 82.886, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 82.869, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 94.477, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 83.625, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 84.509, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 368.775, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 367.002, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 370.005, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 368.318, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 382.433, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsubOpt)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsubOpt)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'cycle'
    --  config:     'mutable (single core, DPsubOpt)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.068, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.065, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.035, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.035, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.034, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.051, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.043, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.045, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.049, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.047, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.056, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.049, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.076, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.083, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.063, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.06, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.065, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.166, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.141, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.144, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.13, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.184, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.217, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.223, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.21, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.216, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.219, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.39, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.37, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.414, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.401, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.363, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 1.486, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 1.578, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 1.335, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 1.332, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 1.336, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 42.192, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 41.878, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 41.153, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 41.836, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 41.909, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 186.363, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 186.207, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 185.072, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 184.908, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 184.687, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsizeSub)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsizeSub)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'cycle'
    --  config:     'mutable (single core, DPsizeSub)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.07, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.027, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.025, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.027, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.027, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.059, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.036, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.043, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.04, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.046, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.052, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.044, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.075, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.076, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.067, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.061, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.076, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.186, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.139, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.148, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.132, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.136, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.26, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.233, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.236, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.232, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.23, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.441, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.47, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.424, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.439, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.448, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 1.95, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 2.039, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 1.967, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 1.992, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 3.512, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 87.985, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 87.662, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 87.757, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 87.108, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 88.653, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 393.535, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 393.429, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 393.949, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 407.679, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 393.689, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TDbasic)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TDbasic)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'cycle'
    --  config:     'mutable (single core, TDbasic)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.077, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.033, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.025, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.026, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.051, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.042, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.036, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.038, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.035, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.053, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.044, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.051, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.078, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.076, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.06, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.065, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.064, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.166, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.142, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.13, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.124, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.125, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.232, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.287, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.209, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.239, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.214, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.424, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.462, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.434, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.406, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.449, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 1.973, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 1.915, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 1.865, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 1.938, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 1.908, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 12.99, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 13.0, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 12.954, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 12.81, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 12.995, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 54.198, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 54.186, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 54.587, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 53.937, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 53.48, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TDMinCutAGaT)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TDMinCutAGaT)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'cycle'
    --  config:     'mutable (single core, TDMinCutAGaT)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.086, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.033, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.015, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.015, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.065, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.054, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.031, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.038, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.033, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.054, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.042, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.053, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.045, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.086, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.063, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.061, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.075, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.064, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.179, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.146, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.134, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.147, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.136, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.249, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.226, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.221, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.256, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.221, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 0.374, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 0.356, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 0.361, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 0.427, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 0.353, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 0.9, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 0.966, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 0.836, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 0.891, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 0.852, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 1.315, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 1.262, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 1.234, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 1.277, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 1.495, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 1.995, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 1.65, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 2.091, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 1.665, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 1.701, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TwoPhaseOptimizer)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TwoPhaseOptimizer)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'cycle'
    --  config:     'mutable (single core, TwoPhaseOptimizer)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 3.208, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 3.189, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 3.279, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 3.544, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 3.253, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 8.821, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 8.579, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 7.869, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 8.113, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 8.019, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 13.172, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 16.08, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 14.701, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 12.957, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 14.446, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 17.369, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 16.768, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 16.467, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 16.757, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 17.671, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 34.012, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 34.391, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 33.031, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 33.239, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 33.195, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 45.145, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 43.709, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 43.63, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 43.683, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 44.02, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 57.298, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 56.46, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 55.864, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 58.015, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 57.296, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 76.225, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 79.938, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 75.14, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 76.44, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 76.557, 4),
        (timestamp_id, experiment_id, configuration_id, 18, 107.938, 0),
        (timestamp_id, experiment_id, configuration_id, 18, 107.028, 1),
        (timestamp_id, experiment_id, configuration_id, 18, 102.255, 2),
        (timestamp_id, experiment_id, configuration_id, 18, 104.661, 3),
        (timestamp_id, experiment_id, configuration_id, 18, 105.246, 4),
        (timestamp_id, experiment_id, configuration_id, 20, 131.797, 0),
        (timestamp_id, experiment_id, configuration_id, 20, 119.867, 1),
        (timestamp_id, experiment_id, configuration_id, 20, 119.319, 2),
        (timestamp_id, experiment_id, configuration_id, 20, 124.963, 3),
        (timestamp_id, experiment_id, configuration_id, 20, 125.58, 4);

    -- Get chart configuration
    PERFORM insert_chartconfig('linear', 'log', 'O', 'Q', 'Number of relations', 'Optimization time (ms)');
    SELECT id FROM "ChartConfig"
    WHERE scale_x='linear' AND scale_y='log'
      AND type_x='O' AND type_y='Q'
      AND label_x='Number of relations' AND label_y='Optimization time (ms)'
    INTO chartconfig_id;

    -- Get experiment
    PERFORM insert_experiment(benchmark_id, 'star', 1, 'Plan enumeration of star queries with methods that are agnostic to cardinalities.', TRUE, chartconfig_id);
    SELECT id FROM "Experiments"
    WHERE benchmark=benchmark_id
      AND name='star'
      AND version=1
    INTO experiment_id;

    -- Update chartconfig of this experiment (if a new one was inserted)
    UPDATE "Experiments"
    SET chart_config=chartconfig_id
    WHERE id=experiment_id;

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPccp)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPccp)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'star'
    --  config:     'mutable (single core, DPccp)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.092, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.03, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.03, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.028, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.058, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.036, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.034, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.039, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.039, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.062, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.051, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.048, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.045, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.089, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.068, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.079, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.068, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.063, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.3, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.261, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.248, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.26, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.205, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.85, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.816, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.819, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.834, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.65, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 3.008, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 3.023, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 3.248, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 3.401, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 3.721, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 26.178, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 26.221, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 27.051, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 25.1, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 23.824, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsizeOpt)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsizeOpt)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'star'
    --  config:     'mutable (single core, DPsizeOpt)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.07, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.029, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.027, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.048, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.04, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.035, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.037, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.037, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.05, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.048, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.044, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.047, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.071, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.068, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.071, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.075, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.059, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.215, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.192, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.214, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.197, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.205, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.989, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.969, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 1.095, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.972, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.988, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 11.764, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 11.729, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 11.134, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 11.348, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 11.401, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 682.507, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 671.11, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 670.821, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 670.596, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 671.668, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsub)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsub)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'star'
    --  config:     'mutable (single core, DPsub)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.067, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.019, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.019, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.045, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.036, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.027, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.028, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.031, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.08, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.048, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.035, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.041, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.04, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.107, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.058, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.071, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.06, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.204, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.196, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.15, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.202, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.196, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.167, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.496, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.432, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.515, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.426, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.487, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 2.053, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 2.036, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 2.169, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 2.031, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 2.045, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 36.462, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 36.334, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 36.456, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 36.253, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 36.379, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsubOpt)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsubOpt)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'star'
    --  config:     'mutable (single core, DPsubOpt)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.089, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.019, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.037, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.018, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.02, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.054, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.072, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.042, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.032, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.027, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.061, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.037, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.04, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.042, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.038, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.124, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.064, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.064, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.059, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.057, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.201, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.126, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.137, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.132, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.129, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.357, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.333, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.326, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.31, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.644, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 1.294, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 1.256, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 1.24, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 1.228, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 1.344, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 19.416, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 19.882, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 19.703, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 19.311, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 19.635, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, DPsizeSub)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, DPsizeSub)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'star'
    --  config:     'mutable (single core, DPsizeSub)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.077, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.025, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.021, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.053, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.031, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.035, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.028, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.055, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.037, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.045, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.037, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.094, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.061, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.07, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.062, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.051, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.199, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.15, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.151, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.151, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.147, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.466, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.43, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.439, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.434, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.442, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 2.142, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 2.041, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 2.066, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 2.04, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 2.228, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 36.724, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 37.04, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 36.591, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 36.837, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 36.487, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TDbasic)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TDbasic)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'star'
    --  config:     'mutable (single core, TDbasic)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.078, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.032, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.021, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.046, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.033, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.034, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.03, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.054, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.043, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.036, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.06, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.038, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.075, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.064, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.065, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.08, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.055, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.179, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.155, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.144, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.163, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.141, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 0.458, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 0.504, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 0.437, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 0.445, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 0.443, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 2.304, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 2.304, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 2.302, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 2.339, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 2.315, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 52.921, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 52.87, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 52.622, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 52.812, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 52.73, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TDMinCutAGaT)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TDMinCutAGaT)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'star'
    --  config:     'mutable (single core, TDMinCutAGaT)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 0.07, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 0.024, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 0.023, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 0.03, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 0.037, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 0.05, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 0.046, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 0.037, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 0.041, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 0.035, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 0.06, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 0.051, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 0.046, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 0.066, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 0.042, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 0.082, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 0.062, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 0.063, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 0.067, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 0.071, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 0.327, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 0.286, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 0.342, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 0.313, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 0.281, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 1.436, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 1.691, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 1.581, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 1.464, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 1.397, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 10.192, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 10.002, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 9.708, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 10.015, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 9.701, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 252.651, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 236.092, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 236.552, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 237.18, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 236.64, 4);

    -- Get config
    PERFORM insert_configuration('mutable (single core, TwoPhaseOptimizer)', 'Execution Time');
    SELECT id FROM "Configurations"
    WHERE name='mutable (single core, TwoPhaseOptimizer)'
      AND parameters='Execution Time'
    INTO configuration_id;

    -- Write measurements
    --  timestamp:  ('6504d630fae4ae96d3e65779747ecbeb3938a08a', '2026-04-14 03:26:12', 'Swarnendus-MacBook-Air.local')
    --  suite:      'plan-enumerators'
    --  benchmark:  'cardinality-agnostic'
    --  experiment: 'star'
    --  config:     'mutable (single core, TwoPhaseOptimizer)'
    INSERT INTO "Measurements" ("timestamp", "experiment", "config", "case", "value", "run_id")
    VALUES
        (timestamp_id, experiment_id, configuration_id, 2, 3.307, 0),
        (timestamp_id, experiment_id, configuration_id, 2, 3.185, 1),
        (timestamp_id, experiment_id, configuration_id, 2, 3.15, 2),
        (timestamp_id, experiment_id, configuration_id, 2, 3.21, 3),
        (timestamp_id, experiment_id, configuration_id, 2, 3.139, 4),
        (timestamp_id, experiment_id, configuration_id, 3, 8.417, 0),
        (timestamp_id, experiment_id, configuration_id, 3, 8.515, 1),
        (timestamp_id, experiment_id, configuration_id, 3, 7.918, 2),
        (timestamp_id, experiment_id, configuration_id, 3, 8.602, 3),
        (timestamp_id, experiment_id, configuration_id, 3, 8.278, 4),
        (timestamp_id, experiment_id, configuration_id, 4, 13.421, 0),
        (timestamp_id, experiment_id, configuration_id, 4, 13.364, 1),
        (timestamp_id, experiment_id, configuration_id, 4, 13.218, 2),
        (timestamp_id, experiment_id, configuration_id, 4, 13.143, 3),
        (timestamp_id, experiment_id, configuration_id, 4, 12.591, 4),
        (timestamp_id, experiment_id, configuration_id, 5, 17.198, 0),
        (timestamp_id, experiment_id, configuration_id, 5, 17.641, 1),
        (timestamp_id, experiment_id, configuration_id, 5, 16.504, 2),
        (timestamp_id, experiment_id, configuration_id, 5, 17.076, 3),
        (timestamp_id, experiment_id, configuration_id, 5, 18.739, 4),
        (timestamp_id, experiment_id, configuration_id, 8, 33.845, 0),
        (timestamp_id, experiment_id, configuration_id, 8, 33.758, 1),
        (timestamp_id, experiment_id, configuration_id, 8, 35.334, 2),
        (timestamp_id, experiment_id, configuration_id, 8, 35.778, 3),
        (timestamp_id, experiment_id, configuration_id, 8, 31.763, 4),
        (timestamp_id, experiment_id, configuration_id, 10, 45.245, 0),
        (timestamp_id, experiment_id, configuration_id, 10, 46.871, 1),
        (timestamp_id, experiment_id, configuration_id, 10, 45.486, 2),
        (timestamp_id, experiment_id, configuration_id, 10, 46.766, 3),
        (timestamp_id, experiment_id, configuration_id, 10, 45.969, 4),
        (timestamp_id, experiment_id, configuration_id, 12, 57.29, 0),
        (timestamp_id, experiment_id, configuration_id, 12, 62.336, 1),
        (timestamp_id, experiment_id, configuration_id, 12, 63.641, 2),
        (timestamp_id, experiment_id, configuration_id, 12, 60.951, 3),
        (timestamp_id, experiment_id, configuration_id, 12, 57.522, 4),
        (timestamp_id, experiment_id, configuration_id, 15, 75.948, 0),
        (timestamp_id, experiment_id, configuration_id, 15, 87.245, 1),
        (timestamp_id, experiment_id, configuration_id, 15, 81.643, 2),
        (timestamp_id, experiment_id, configuration_id, 15, 77.805, 3),
        (timestamp_id, experiment_id, configuration_id, 15, 81.05, 4);
END$$;