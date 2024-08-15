-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create the power_consumption table
CREATE TABLE power_consumption (
    date_time TIMESTAMP NOT NULL,
    global_active_power FLOAT,
    global_reactive_power FLOAT,
    voltage FLOAT,
    global_intensity FLOAT,
    sub_metering_1 FLOAT,
    sub_metering_2 FLOAT,
    sub_metering_3 FLOAT
);

-- Convert to hypertable
SELECT create_hypertable('power_consumption', 'date_time');

-- Create indexes
CREATE INDEX idx_date_power ON power_consumption (date_time, global_active_power);
CREATE INDEX idx_high_power ON power_consumption (date_time, global_active_power) WHERE global_active_power > 5;
CREATE INDEX idx_hour_of_day ON power_consumption ((EXTRACT(HOUR FROM date_time)));

-- Set up retention policy
SELECT add_retention_policy('power_consumption', INTERVAL '2 years');

-- Enable compression
ALTER TABLE power_consumption SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'date_time DESC'
);

SELECT add_compression_policy('power_consumption', INTERVAL '7 days');

-- Create continuous aggregate
CREATE MATERIALIZED VIEW daily_power_consumption
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 day', date_time) AS day,
       AVG(global_active_power) AS avg_power,
       MAX(global_active_power) AS max_power,
       MIN(global_active_power) AS min_power
FROM power_consumption
GROUP BY time_bucket('1 day', date_time);

SELECT add_continuous_aggregate_policy('daily_power_consumption',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- Set up maintenance jobs
SELECT cron.schedule('0 2 * * 0', $$
    VACUUM ANALYZE power_consumption;
$$);

SELECT cron.schedule('0 3 * * 0', $$
    ANALYZE VERBOSE power_consumption;
$$);