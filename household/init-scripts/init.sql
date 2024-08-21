 -- CREATE DATABASE power_consumption_db;

-- Grant all privileges on the database
GRANT ALL PRIVILEGES ON DATABASE power_consumption_db TO poweruser;

-- Grant all privileges on all tables in the public schema
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO poweruser;

-- Grant all privileges on all sequences in the public schema
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO poweruser;

-- Grant all privileges on all functions in the public schema
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO poweruser;

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Enable pg_cron extension
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Enable the UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable the PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Optionally, enable additional PostGIS-related extensions
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

DROP TABLE IF EXISTS power_consumption CASCADE;

-- Create the main power_consumption table
CREATE TABLE IF NOT EXISTS power_consumption (
    date_time TIMESTAMP NOT NULL,
    global_active_power FLOAT,
    global_reactive_power FLOAT,
    voltage FLOAT,
    global_intensity FLOAT,
    sub_metering_1 FLOAT,
    sub_metering_2 FLOAT,
    sub_metering_3 FLOAT
) PARTITION BY RANGE (date_time);

-- Create partitions for each year from 2006 to 2011 (adjust as needed)
DO $$
DECLARE
    year INT;
BEGIN
    FOR year IN 2006..2011 LOOP
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS power_consumption_y%s
            PARTITION OF power_consumption
            FOR VALUES FROM (%L) TO (%L)',
            year,
            year || '-01-01',
            (year + 1) || '-01-01'
        );
    END LOOP;
END $$;

-- Create indexes for faster querying
CREATE INDEX IF NOT EXISTS idx_date_power ON power_consumption (date_time, global_active_power);
CREATE INDEX IF NOT EXISTS idx_high_power ON power_consumption (date_time, global_active_power) WHERE global_active_power > 5;
