SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'power_consumption';


SELECT
    COUNT(*) as total_records,
    MIN(date_time) as start_date,
    MAX(date_time) as end_date,
    AVG(global_active_power) as avg_active_power,
    MAX(global_active_power) as max_active_power,
    MIN(global_active_power) as min_active_power,
    AVG(voltage) as avg_voltage,
    AVG(global_intensity) as avg_intensity
FROM power_consumption;


SELECT
    DATE_TRUNC('hour', date_time) as hour,
    AVG(global_active_power) as avg_power
FROM power_consumption
GROUP BY DATE_TRUNC('hour', date_time)
ORDER BY hour;


SELECT
    DATE_TRUNC('day', date_time) as day,
    AVG(global_active_power) as avg_power,
    MAX(global_active_power) as max_power,
    MIN(global_active_power) as min_power
FROM power_consumption
GROUP BY DATE_TRUNC('day', date_time)
ORDER BY day;

-- 1. Basic Statistics View
CREATE OR REPLACE VIEW vw_power_basic_stats AS
SELECT
    COUNT(*) as total_records,
    MIN(date_time) as start_date,
    MAX(date_time) as end_date,
    AVG(global_active_power) as avg_active_power,
    MAX(global_active_power) as max_active_power,
    MIN(global_active_power) as min_active_power,
    AVG(voltage) as avg_voltage,
    AVG(global_intensity) as avg_intensity
FROM power_consumption;

SELECT * FROM vw_power_basic_stats;

-- 2. Hourly Power Consumption View
CREATE OR REPLACE VIEW vw_hourly_power_consumption AS
SELECT
    DATE_TRUNC('hour', date_time) as hour,
    AVG(global_active_power) as avg_power
FROM power_consumption
GROUP BY DATE_TRUNC('hour', date_time)
ORDER BY hour;

SELECT * FROM vw_hourly_power_consumption;

-- 3. Daily Power Consumption View
CREATE OR REPLACE VIEW vw_daily_power_consumption AS
SELECT
    DATE_TRUNC('day', date_time) as day,
    AVG(global_active_power) as avg_power,
    MAX(global_active_power) as max_power,
    MIN(global_active_power) as min_power
FROM power_consumption
GROUP BY DATE_TRUNC('day', date_time)
ORDER BY day;

SELECT * FROM vw_daily_power_consumption;

-- 4. Monthly Power Consumption View
CREATE OR REPLACE VIEW vw_monthly_power_consumption AS
SELECT
    DATE_TRUNC('month', date_time) as month,
    AVG(global_active_power) as avg_power
FROM power_consumption
GROUP BY DATE_TRUNC('month', date_time)
ORDER BY month;

SELECT * FROM vw_monthly_power_consumption;

-- 5. Day of Week Analysis View
CREATE OR REPLACE VIEW vw_day_of_week_power_consumption AS
SELECT
    EXTRACT(DOW FROM date_time) as day_of_week,
    AVG(global_active_power) as avg_power
FROM power_consumption
GROUP BY EXTRACT(DOW FROM date_time)
ORDER BY day_of_week;

SELECT * FROM vw_day_of_week_power_consumption;

-- 6. Power Consumption Distribution View
CREATE OR REPLACE VIEW vw_power_consumption_distribution AS
SELECT
    WIDTH_BUCKET(global_active_power, 0, 10, 20) as bucket,
    COUNT(*) as count,
    MIN(global_active_power) as min_power,
    MAX(global_active_power) as max_power
FROM power_consumption
GROUP BY bucket
ORDER BY bucket;

SELECT * FROM vw_power_consumption_distribution;

-- 7. Correlation Analysis View
CREATE OR REPLACE VIEW vw_power_correlations AS
SELECT
    corr(global_active_power, global_reactive_power) as active_reactive_corr,
    corr(global_active_power, voltage) as active_voltage_corr,
    corr(global_active_power, global_intensity) as active_intensity_corr
FROM power_consumption;

SELECT * FROM vw_power_correlations;

-- 8. Submetering Analysis View
CREATE OR REPLACE VIEW vw_submetering_analysis AS
SELECT
    AVG(sub_metering_1) as avg_sub1,
    AVG(sub_metering_2) as avg_sub2,
    AVG(sub_metering_3) as avg_sub3,
    AVG(global_active_power * 1000 / 60 - (sub_metering_1 + sub_metering_2 + sub_metering_3)) as avg_sub_other
FROM power_consumption;

SELECT * FROM vw_submetering_analysis;

-- 1. Basic Statistics View
SELECT * FROM vw_power_basic_stats;

-- 2. Hourly Power Consumption View
-- Get all hourly data
SELECT * FROM vw_hourly_power_consumption;

-- Get hourly data for a specific day
SELECT * FROM vw_hourly_power_consumption
WHERE hour::date = '2010-01-01';

-- Get average power consumption for each hour of the day
SELECT EXTRACT(HOUR FROM hour) AS hour_of_day, AVG(avg_power) AS avg_power
FROM vw_hourly_power_consumption
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Get the hour with the highest average power consumption
SELECT * FROM vw_hourly_power_consumption
ORDER BY avg_power DESC
LIMIT 1;

-- 3. Daily Power Consumption View
-- Get all daily data
SELECT * FROM vw_daily_power_consumption;

-- Get daily data for a specific month
SELECT * FROM vw_daily_power_consumption
WHERE day >= '2022-01-01' AND day < '2022-02-01';

-- Get the day with the highest peak power consumption
SELECT * FROM vw_daily_power_consumption
ORDER BY max_power DESC
LIMIT 1;

-- Get days where power consumption was above average
SELECT * FROM vw_daily_power_consumption
WHERE avg_power > (SELECT AVG(avg_power) FROM vw_daily_power_consumption);

-- Calculate the daily power consumption range (max - min)
SELECT day, max_power - min_power AS power_range
FROM vw_daily_power_consumption
ORDER BY power_range DESC;

-- 4. Monthly Power Consumption View
-- Get all monthly data
SELECT * FROM vw_monthly_power_consumption;

-- Get monthly data for a specific year
SELECT * FROM vw_monthly_power_consumption
WHERE EXTRACT(YEAR FROM month) = 2022;

-- Get the month with the highest average power consumption
SELECT * FROM vw_monthly_power_consumption
ORDER BY avg_power DESC
LIMIT 1;

-- Calculate year-over-year change in power consumption
SELECT
    current_year.month,
    current_year.avg_power AS current_year_power,
    prev_year.avg_power AS prev_year_power,
    (current_year.avg_power - prev_year.avg_power) / prev_year.avg_power * 100 AS yoy_change_percent
FROM vw_monthly_power_consumption current_year
         LEFT JOIN vw_monthly_power_consumption prev_year
                   ON EXTRACT(MONTH FROM current_year.month) = EXTRACT(MONTH FROM prev_year.month)
                       AND EXTRACT(YEAR FROM current_year.month) = EXTRACT(YEAR FROM prev_year.month) + 1
ORDER BY current_year.month;

-- 5. Day of Week Analysis View
-- Get all day of week data
SELECT * FROM vw_day_of_week_power_consumption;

-- Get weekday vs weekend average power consumption
SELECT
    CASE WHEN day_of_week IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    AVG(avg_power) AS avg_power
FROM vw_day_of_week_power_consumption
GROUP BY CASE WHEN day_of_week IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END;

-- 6. Power Consumption Distribution View
-- Get all distribution data
SELECT * FROM vw_power_consumption_distribution;

-- Calculate the percentage of time spent in each consumption bucket
SELECT
    bucket,
    count,
    min_power,
    max_power,
    count * 100.0 / SUM(count) OVER () AS percent_of_time
FROM vw_power_consumption_distribution;

-- Find the most common power consumption range
SELECT * FROM vw_power_consumption_distribution
ORDER BY count DESC
LIMIT 1;

-- 7. Correlation Analysis View
-- Get all correlation data
SELECT * FROM vw_power_correlations;

-- 8. Submetering Analysis View
-- Get all submetering data
SELECT * FROM vw_submetering_analysis;

-- Calculate the percentage of total consumption for each submetering
SELECT
    avg_sub1 / (avg_sub1 + avg_sub2 + avg_sub3 + avg_sub_other) * 100 AS percent_sub1,
    avg_sub2 / (avg_sub1 + avg_sub2 + avg_sub3 + avg_sub_other) * 100 AS percent_sub2,
    avg_sub3 / (avg_sub1 + avg_sub2 + avg_sub3 + avg_sub_other) * 100 AS percent_sub3,
    avg_sub_other / (avg_sub1 + avg_sub2 + avg_sub3 + avg_sub_other) * 100 AS percent_other
FROM vw_submetering_analysis;


-- Find periods of unusual high consumption (e.g., more than 2 standard deviations above mean)
WITH stats AS (
    SELECT AVG(avg_power) AS mean_power, STDDEV(avg_power) AS stddev_power
    FROM vw_daily_power_consumption
)
SELECT vw.*, (vw.avg_power - stats.mean_power) / stats.stddev_power AS z_score
FROM vw_daily_power_consumption vw, stats
WHERE (vw.avg_power - stats.mean_power) / stats.stddev_power > 2
ORDER BY vw.avg_power DESC;

-- Analyze seasonal patterns
SELECT
    EXTRACT(YEAR FROM month) AS year,
    CASE
        WHEN EXTRACT(MONTH FROM month) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM month) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM month) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
        END AS season,
    AVG(avg_power) AS avg_seasonal_power
FROM vw_monthly_power_consumption
GROUP BY year, season
ORDER BY year, CASE season
                   WHEN 'Winter' THEN 1
                   WHEN 'Spring' THEN 2
                   WHEN 'Summer' THEN 3
                   WHEN 'Fall' THEN 4
    END;

-- Analyze power factor (assuming global_active_power and global_reactive_power are in the same units)
SELECT
    AVG(global_active_power / SQRT(global_active_power^2 + global_reactive_power^2)) AS avg_power_factor
FROM power_consumption;

-- Find the top 10 days with highest power consumption variability
SELECT day, max_power - min_power AS power_range
FROM vw_daily_power_consumption
ORDER BY power_range DESC
LIMIT 10;


-- 1. Daily Pattern Identification

-- Create a view for hourly averages across all days
CREATE OR REPLACE VIEW vw_daily_pattern AS
SELECT
    EXTRACT(HOUR FROM date_time)::NUMERIC AS hour,
    AVG(global_active_power)::FLOAT AS avg_power
FROM power_consumption
GROUP BY EXTRACT(HOUR FROM date_time)
ORDER BY hour;

-- Query to view the daily pattern
SELECT * FROM vw_daily_pattern;

-- 2. Weekly Pattern Identification

-- Create a view for daily averages for each day of the week
CREATE OR REPLACE VIEW vw_weekly_pattern AS
SELECT
    EXTRACT(DOW FROM date_time) AS day_of_week,
    AVG(global_active_power) AS avg_power
FROM power_consumption
GROUP BY EXTRACT(DOW FROM date_time)
ORDER BY day_of_week;

-- Query to view the weekly pattern
SELECT * FROM vw_weekly_pattern;

-- 3. Seasonal Pattern Identification

-- Create a view for monthly averages to identify seasonal patterns
CREATE OR REPLACE VIEW vw_seasonal_pattern AS
SELECT
    EXTRACT(MONTH FROM date_time) AS month,
    AVG(global_active_power) AS avg_power
FROM power_consumption
GROUP BY EXTRACT(MONTH FROM date_time)
ORDER BY month;

-- Query to view the seasonal pattern
SELECT * FROM vw_seasonal_pattern;

-- 4. Function to identify peak hours (No changes needed, but included for completeness)
CREATE OR REPLACE FUNCTION get_peak_hours(threshold FLOAT)
    RETURNS TABLE (hour NUMERIC, avg_power FLOAT) AS $$
BEGIN
    RETURN QUERY
        SELECT vw_daily_pattern.hour, vw_daily_pattern.avg_power
        FROM vw_daily_pattern
        WHERE vw_daily_pattern.avg_power > threshold
        ORDER BY vw_daily_pattern.avg_power DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage example: Get peak hours above 1.5 kW
SELECT * FROM get_peak_hours(1.5);


-- 7. View to identify day-of-week and hour combinations with highest consumption
CREATE OR REPLACE VIEW vw_day_hour_pattern AS
SELECT
    EXTRACT(DOW FROM date_time) AS day_of_week,
    EXTRACT(HOUR FROM date_time) AS hour,
    AVG(global_active_power) AS avg_power
FROM power_consumption
GROUP BY EXTRACT(DOW FROM date_time), EXTRACT(HOUR FROM date_time)
ORDER BY avg_power DESC;

-- Query to get top 10 day-hour combinations with highest consumption
SELECT * FROM vw_day_hour_pattern LIMIT 10;

-- 9. View for yearly patterns
CREATE OR REPLACE VIEW vw_yearly_pattern AS
SELECT
    EXTRACT(YEAR FROM date_time)::NUMERIC AS year,
    AVG(global_active_power)::FLOAT AS avg_power
FROM power_consumption
GROUP BY EXTRACT(YEAR FROM date_time)
ORDER BY year;

-- Query to view yearly patterns
SELECT * FROM vw_yearly_pattern;


CREATE OR REPLACE FUNCTION detect_regular_spikes(interval_hours INT, threshold FLOAT)
    RETURNS TABLE (start_time TIMESTAMP WITHOUT TIME ZONE, end_time TIMESTAMP WITHOUT TIME ZONE, avg_power FLOAT) AS $$
BEGIN
    RETURN QUERY
        WITH intervals AS (
            SELECT
                date_trunc('hour', date_time)::TIMESTAMP WITHOUT TIME ZONE AS start_time,
                (date_trunc('hour', date_time) + (interval_hours || ' hours')::INTERVAL)::TIMESTAMP WITHOUT TIME ZONE AS end_time,
                AVG(global_active_power)::FLOAT AS avg_power
            FROM power_consumption
            GROUP BY date_trunc('hour', date_time)
        )
        SELECT intervals.start_time, intervals.end_time, intervals.avg_power
        FROM intervals
        WHERE intervals.avg_power > threshold
        ORDER BY intervals.avg_power DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM detect_regular_spikes(3, 2) LIMIT 10;

CREATE OR REPLACE FUNCTION compare_weekday_weekend()
    RETURNS TABLE (day_type TEXT, avg_power FLOAT) AS $$
BEGIN
    RETURN QUERY
        SELECT
            CASE WHEN vw_weekly_pattern.day_of_week IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
            AVG(vw_weekly_pattern.avg_power)::FLOAT AS avg_power
        FROM vw_weekly_pattern
        GROUP BY CASE WHEN vw_weekly_pattern.day_of_week IN (0, 6) THEN 'Weekend' ELSE 'Weekday' END;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM compare_weekday_weekend();

CREATE OR REPLACE FUNCTION get_seasonal_peaks()
    RETURNS TABLE (season TEXT, month NUMERIC, avg_power FLOAT) AS $$
BEGIN
    RETURN QUERY
        WITH seasonal_data AS (
            SELECT
                CASE
                    WHEN vsp.month IN (12, 1, 2) THEN 'Winter'
                    WHEN vsp.month IN (3, 4, 5) THEN 'Spring'
                    WHEN vsp.month IN (6, 7, 8) THEN 'Summer'
                    ELSE 'Fall'
                    END AS season_name,
                vsp.month,
                vsp.avg_power,
                ROW_NUMBER() OVER (PARTITION BY
                    CASE
                        WHEN vsp.month IN (12, 1, 2) THEN 'Winter'
                        WHEN vsp.month IN (3, 4, 5) THEN 'Spring'
                        WHEN vsp.month IN (6, 7, 8) THEN 'Summer'
                        ELSE 'Fall'
                        END
                    ORDER BY vsp.avg_power DESC) AS rn
            FROM vw_seasonal_pattern vsp
        )
        SELECT seasonal_data.season_name, seasonal_data.month, seasonal_data.avg_power
        FROM seasonal_data
        WHERE seasonal_data.rn = 1
        ORDER BY seasonal_data.avg_power DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_seasonal_peaks();

CREATE OR REPLACE FUNCTION identify_consumption_changes(change_threshold FLOAT)
    RETURNS TABLE (
                      year_val NUMERIC,
                      avg_power FLOAT,
                      prev_year_power FLOAT,
                      power_change FLOAT,
                      change_percentage FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH yearly_changes AS (
            SELECT
                vw_yearly_pattern.year AS year_val,
                vw_yearly_pattern.avg_power,
                LAG(vw_yearly_pattern.avg_power) OVER (ORDER BY vw_yearly_pattern.year) AS prev_year_power,
                vw_yearly_pattern.avg_power - LAG(vw_yearly_pattern.avg_power) OVER (ORDER BY vw_yearly_pattern.year) AS power_change,
                (vw_yearly_pattern.avg_power - LAG(vw_yearly_pattern.avg_power) OVER (ORDER BY vw_yearly_pattern.year)) / NULLIF(LAG(vw_yearly_pattern.avg_power) OVER (ORDER BY vw_yearly_pattern.year), 0) * 100 AS change_percentage
            FROM vw_yearly_pattern
        )
        SELECT yearly_changes.*
        FROM yearly_changes
        WHERE ABS(yearly_changes.change_percentage) > change_threshold AND yearly_changes.prev_year_power IS NOT NULL
        ORDER BY ABS(yearly_changes.change_percentage) DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM identify_consumption_changes(5);

CREATE OR REPLACE FUNCTION detect_anomalies_zscore(z_threshold FLOAT)
    RETURNS TABLE (
                      date_time TIMESTAMP WITH TIME ZONE,
                      global_active_power FLOAT,
                      zscore FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH stats AS (
            SELECT
                AVG(pc.global_active_power) AS mean_power,
                STDDEV(pc.global_active_power) AS stddev_power
            FROM power_consumption pc
        )
        SELECT
            pc.date_time,
            pc.global_active_power,
            (pc.global_active_power - stats.mean_power) / NULLIF(stats.stddev_power, 0) AS zscore
        FROM power_consumption pc, stats
        WHERE ABS((pc.global_active_power - stats.mean_power) / NULLIF(stats.stddev_power, 0)) > z_threshold
        ORDER BY ABS((pc.global_active_power - stats.mean_power) / NULLIF(stats.stddev_power, 0)) DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage: Detect anomalies with Z-score > 3
SELECT * FROM detect_anomalies_zscore(3) LIMIT 10;


CREATE OR REPLACE FUNCTION detect_anomalies_moving_avg(window_size INT, threshold FLOAT)
    RETURNS TABLE (
                      date_time TIMESTAMP WITH TIME ZONE,
                      global_active_power FLOAT,
                      moving_avg FLOAT,
                      deviation FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH moving_avg AS (
            SELECT
                pc.date_time,
                pc.global_active_power,
                AVG(pc.global_active_power) OVER (
                    ORDER BY pc.date_time
                    ROWS BETWEEN window_size PRECEDING AND CURRENT ROW
                    ) AS moving_avg
            FROM power_consumption pc
        )
        SELECT
            moving_avg.date_time,
            moving_avg.global_active_power,
            moving_avg.moving_avg,
            ABS(moving_avg.global_active_power - moving_avg.moving_avg) AS deviation
        FROM moving_avg
        WHERE ABS(moving_avg.global_active_power - moving_avg.moving_avg) > threshold
        ORDER BY deviation DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage: Detect anomalies using a 24-hour window and threshold of 2 kW
SELECT * FROM detect_anomalies_moving_avg(24, 2) LIMIT 10;


CREATE OR REPLACE FUNCTION detect_seasonal_anomalies(threshold FLOAT)
    RETURNS TABLE (
                      date_time TIMESTAMP WITH TIME ZONE,
                      global_active_power FLOAT,
                      seasonal_avg FLOAT,
                      deviation FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH seasonal_avg AS (
            SELECT
                pc.date_time,
                pc.global_active_power,
                AVG(pc.global_active_power) OVER (
                    PARTITION BY EXTRACT(MONTH FROM pc.date_time), EXTRACT(DOW FROM pc.date_time), EXTRACT(HOUR FROM pc.date_time)
                    ) AS seasonal_avg
            FROM power_consumption pc
        )
        SELECT
            seasonal_avg.date_time,
            seasonal_avg.global_active_power,
            seasonal_avg.seasonal_avg,
            ABS(seasonal_avg.global_active_power - seasonal_avg.seasonal_avg) AS deviation
        FROM seasonal_avg
        WHERE ABS(seasonal_avg.global_active_power - seasonal_avg.seasonal_avg) > threshold
        ORDER BY deviation DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage: Detect seasonal anomalies with a threshold of 3 kW
SELECT * FROM detect_seasonal_anomalies(3) LIMIT 10;

CREATE OR REPLACE FUNCTION detect_sudden_changes(change_threshold FLOAT)
    RETURNS TABLE (
                      date_time TIMESTAMP WITH TIME ZONE,
                      global_active_power FLOAT,
                      previous_power FLOAT,
                      change FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH power_changes AS (
            SELECT
                pc.date_time,
                pc.global_active_power,
                LAG(pc.global_active_power) OVER (ORDER BY pc.date_time) AS previous_power,
                pc.global_active_power - LAG(pc.global_active_power) OVER (ORDER BY pc.date_time) AS change
            FROM power_consumption pc
        )
        SELECT
            power_changes.date_time,
            power_changes.global_active_power,
            power_changes.previous_power,
            power_changes.change
        FROM power_changes
        WHERE ABS(power_changes.change) > change_threshold
        ORDER BY ABS(power_changes.change) DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage: Detect sudden changes greater than 5 kW
SELECT * FROM detect_sudden_changes(5) LIMIT 10;

-- 5. Anomaly Detection Dashboard View
CREATE OR REPLACE VIEW vw_anomaly_dashboard AS
WITH
    zscore_anomalies AS (
        SELECT * FROM detect_anomalies_zscore(3) LIMIT 5
    ),
    moving_avg_anomalies AS (
        SELECT * FROM detect_anomalies_moving_avg(24, 2) LIMIT 5
    ),
    seasonal_anomalies AS (
        SELECT * FROM detect_seasonal_anomalies(3) LIMIT 5
    ),
    sudden_changes AS (
        SELECT * FROM detect_sudden_changes(5) LIMIT 5
    )
SELECT 'Z-Score' AS method, date_time, global_active_power, zscore AS metric FROM zscore_anomalies
UNION ALL
SELECT 'Moving Average' AS method, date_time, global_active_power, deviation AS metric FROM moving_avg_anomalies
UNION ALL
SELECT 'Seasonal' AS method, date_time, global_active_power, deviation AS metric FROM seasonal_anomalies
UNION ALL
SELECT 'Sudden Change' AS method, date_time, global_active_power, change AS metric FROM sudden_changes
ORDER BY method, metric DESC;

-- View the anomaly dashboard
SELECT * FROM vw_anomaly_dashboard;


CREATE OR REPLACE FUNCTION forecast_simple_moving_average(
    forecast_start TIMESTAMP WITH TIME ZONE,
    forecast_end TIMESTAMP WITH TIME ZONE,
    window_size INT
)
    RETURNS TABLE (
                      forecast_date TIMESTAMP WITH TIME ZONE,
                      forecast_value FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH daily_avg AS (
            SELECT
                DATE_TRUNC('day', pc.date_time) AS day,
                AVG(pc.global_active_power) AS avg_power
            FROM power_consumption pc
            WHERE pc.date_time < forecast_start
            GROUP BY DATE_TRUNC('day', pc.date_time)
        ),
             forecast AS (
                 SELECT
                     gs AS forecast_date,
                     AVG(da.avg_power) OVER (
                         ORDER BY da.day
                         ROWS BETWEEN window_size PRECEDING AND 1 PRECEDING
                         ) AS forecast_value
                 FROM daily_avg da,
                      generate_series(forecast_start, forecast_end, '1 day'::INTERVAL) AS gs
             )
        SELECT f.forecast_date, f.forecast_value
        FROM forecast f
        WHERE f.forecast_value IS NOT NULL;
END;
$$ LANGUAGE plpgsql;


-- Usage: Forecast next 7 days using a 30-day moving average
SELECT * FROM forecast_simple_moving_average(CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 30);



CREATE OR REPLACE FUNCTION forecast_weighted_moving_average(
    forecast_start TIMESTAMP WITH TIME ZONE,
    forecast_end TIMESTAMP WITH TIME ZONE,
    window_size INT
)
    RETURNS TABLE (
                      forecast_date TIMESTAMP WITH TIME ZONE,
                      forecast_value FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH daily_avg AS (
            SELECT
                DATE_TRUNC('day', date_time AT TIME ZONE 'UTC') AS day,
                AVG(global_active_power) AS avg_power
            FROM power_consumption
            WHERE date_time < forecast_start
            GROUP BY DATE_TRUNC('day', date_time AT TIME ZONE 'UTC')
        ),
             row_numbered_avg AS (
                 SELECT
                     day,
                     avg_power,
                     ROW_NUMBER() OVER (ORDER BY day DESC) AS row_num
                 FROM daily_avg
             ),
             weighted_avg AS (
                 SELECT
                     day,
                     avg_power,
                     SUM(avg_power * row_num) OVER (
                         ORDER BY day
                         ROWS BETWEEN window_size PRECEDING AND 1 PRECEDING
                         ) AS weighted_sum,
                     SUM(row_num) OVER (
                         ORDER BY day
                         ROWS BETWEEN window_size PRECEDING AND 1 PRECEDING
                         ) AS weight_sum
                 FROM row_numbered_avg
             )
        SELECT
            generate_series(forecast_start, forecast_end, '1 day'::INTERVAL) AS forecast_date,
            weighted_sum / NULLIF(weight_sum, 0) AS forecast_value
        FROM weighted_avg
        WHERE weighted_sum IS NOT NULL
        ORDER BY forecast_date;
END;
$$ LANGUAGE plpgsql;

-- Usage: Forecast next 7 days using a 30-day weighted moving average
SELECT * FROM forecast_weighted_moving_average(CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 30);



CREATE OR REPLACE FUNCTION forecast_exponential_smoothing(
    forecast_start TIMESTAMP WITH TIME ZONE,
    forecast_end TIMESTAMP WITH TIME ZONE,
    alpha DOUBLE PRECISION
)
    RETURNS TABLE (
                      forecast_date TIMESTAMP WITH TIME ZONE,
                      forecast_value FLOAT
                  ) AS $$
DECLARE
    last_value FLOAT;
    last_date TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Get the last known value and date
    SELECT pc.global_active_power, pc.date_time
    INTO last_value, last_date
    FROM power_consumption pc
    WHERE pc.date_time < forecast_start
    ORDER BY pc.date_time DESC
    LIMIT 1;

    RETURN QUERY
        WITH RECURSIVE forecast AS (
            -- Base case: use the last known value
            SELECT last_date AS forecast_date, last_value AS forecast_value

            UNION ALL

            -- Recursive case: calculate the next forecast
            SELECT
                f.forecast_date + INTERVAL '1 day',
                alpha * COALESCE((
                                     SELECT AVG(pc.global_active_power)
                                     FROM power_consumption pc
                                     WHERE DATE_TRUNC('day', pc.date_time) = DATE_TRUNC('day', f.forecast_date)
                                 ), f.forecast_value) + (1 - alpha) * f.forecast_value
            FROM forecast f
            WHERE f.forecast_date < forecast_end
        )
        SELECT f.forecast_date, f.forecast_value
        FROM forecast f
        WHERE f.forecast_date >= forecast_start
        ORDER BY f.forecast_date;
END;
$$ LANGUAGE plpgsql;


-- Usage: Forecast next 7 days using exponential smoothing with alpha = 0.3
SELECT * FROM forecast_exponential_smoothing(CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 0.3);


CREATE OR REPLACE FUNCTION forecast_seasonal_naive(
    forecast_start TIMESTAMP WITH TIME ZONE,
    forecast_end TIMESTAMP WITH TIME ZONE,
    season_length INT
)
    RETURNS TABLE (
                      forecast_date TIMESTAMP WITH TIME ZONE,
                      forecast_value FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH historical_data AS (
            SELECT
                pc.date_time,
                pc.global_active_power,
                ROW_NUMBER() OVER (ORDER BY pc.date_time DESC) AS rn
            FROM power_consumption pc
            WHERE pc.date_time < forecast_start
            ORDER BY pc.date_time DESC
            LIMIT (EXTRACT(EPOCH FROM (forecast_end - forecast_start)) / 86400)::INT * season_length
        )
        SELECT
            gs.forecast_date,
            AVG(pc.global_active_power) AS forecast_value
        FROM generate_series(forecast_start, forecast_end, '1 day'::INTERVAL) AS gs(forecast_date)
                 LEFT JOIN historical_data pc ON
            (EXTRACT(EPOCH FROM (gs.forecast_date - forecast_start)) / 86400)::INT % season_length = pc.rn % season_length
        GROUP BY gs.forecast_date
        ORDER BY gs.forecast_date;
END;
$$ LANGUAGE plpgsql;

-- Usage: Forecast next 7 days using seasonal naive method with a 7-day season (weekly pattern)
SELECT * FROM forecast_seasonal_naive(CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 7);


CREATE OR REPLACE FUNCTION evaluate_forecast_accuracy(
    forecast_start TIMESTAMP WITH TIME ZONE,
    forecast_end TIMESTAMP WITH TIME ZONE
)
    RETURNS TABLE (
                      method TEXT,
                      mae FLOAT,
                      rmse FLOAT,
                      mape FLOAT
                  ) AS $$
DECLARE
    actual_values FLOAT[];
    forecast_values FLOAT[];
    n INT;
BEGIN
    -- Get actual values
    SELECT ARRAY_AGG(global_active_power ORDER BY date_time)
    INTO actual_values
    FROM power_consumption
    WHERE date_time BETWEEN forecast_start AND forecast_end;

    n := ARRAY_LENGTH(actual_values, 1);

    -- Simple Moving Average
    SELECT ARRAY_AGG(forecast_value ORDER BY forecast_date)
    INTO forecast_values
    FROM forecast_simple_moving_average(forecast_start, forecast_end, 30);

    RETURN QUERY
        SELECT
            'Simple Moving Average' AS method,
            (SELECT SUM(ABS(actual_values[i] - forecast_values[i])) / n
             FROM generate_series(1, n) i) AS mae,
            SQRT((SELECT SUM(POW(actual_values[i] - forecast_values[i], 2)) / n
                  FROM generate_series(1, n) i)) AS rmse,
            (SELECT SUM(ABS((actual_values[i] - forecast_values[i]) / actual_values[i])) / n * 100
             FROM generate_series(1, n) i) AS mape;

    -- Weighted Moving Average
    SELECT ARRAY_AGG(forecast_value ORDER BY forecast_date)
    INTO forecast_values
    FROM forecast_weighted_moving_average(forecast_start, forecast_end, 30);

    RETURN QUERY
        SELECT
            'Weighted Moving Average' AS method,
            (SELECT SUM(ABS(actual_values[i] - forecast_values[i])) / n
             FROM generate_series(1, n) i) AS mae,
            SQRT((SELECT SUM(POW(actual_values[i] - forecast_values[i], 2)) / n
                  FROM generate_series(1, n) i)) AS rmse,
            (SELECT SUM(ABS((actual_values[i] - forecast_values[i]) / actual_values[i])) / n * 100
             FROM generate_series(1, n) i) AS mape;

    -- Exponential Smoothing
    SELECT ARRAY_AGG(forecast_value ORDER BY forecast_date)
    INTO forecast_values
    FROM forecast_exponential_smoothing(forecast_start, forecast_end, 0.3);

    RETURN QUERY
        SELECT
            'Exponential Smoothing' AS method,
            (SELECT SUM(ABS(actual_values[i] - forecast_values[i])) / n
             FROM generate_series(1, n) i) AS mae,
            SQRT((SELECT SUM(POW(actual_values[i] - forecast_values[i], 2)) / n
                  FROM generate_series(1, n) i)) AS rmse,
            (SELECT SUM(ABS((actual_values[i] - forecast_values[i]) / actual_values[i])) / n * 100
             FROM generate_series(1, n) i) AS mape;

    -- Seasonal Naive
    SELECT ARRAY_AGG(forecast_value ORDER BY forecast_date)
    INTO forecast_values
    FROM forecast_seasonal_naive(forecast_start, forecast_end, 7);

    RETURN QUERY
        SELECT
            'Seasonal Naive' AS method,
            (SELECT SUM(ABS(actual_values[i] - forecast_values[i])) / n
             FROM generate_series(1, n) i) AS mae,
            SQRT((SELECT SUM(POW(actual_values[i] - forecast_values[i], 2)) / n
                  FROM generate_series(1, n) i)) AS rmse,
            (SELECT SUM(ABS((actual_values[i] - forecast_values[i]) / actual_values[i])) / n * 100
             FROM generate_series(1, n) i) AS mape;
END;
$$ LANGUAGE plpgsql;

-- Usage: Evaluate forecast accuracy for the last 30 days
SELECT * FROM evaluate_forecast_accuracy(CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE);

CREATE OR REPLACE FUNCTION calculate_power_factor()
    RETURNS TABLE (
                      date_time TIMESTAMP WITH TIME ZONE,
                      power_factor FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            pc.date_time,
            pc.global_active_power / NULLIF(SQRT(POW(pc.global_active_power, 2) + POW(pc.global_reactive_power, 2)), 0) AS power_factor
        FROM power_consumption pc
        WHERE pc.global_active_power IS NOT NULL AND pc.global_reactive_power IS NOT NULL
        ORDER BY pc.date_time;
END;
$$ LANGUAGE plpgsql;

-- Usage: Calculate power factor
SELECT * FROM calculate_power_factor() LIMIT 10;


CREATE OR REPLACE VIEW vw_efficiency_analysis AS
WITH power_factor_calc AS (
    SELECT * FROM calculate_power_factor()
),
     efficiency_metrics AS (
         SELECT
             DATE_TRUNC('hour', pc.date_time) AS hour,
             AVG(pc.global_active_power) AS avg_active_power,
             AVG(pc.global_reactive_power) AS avg_reactive_power,
             AVG(pf.power_factor) AS avg_power_factor,
             SUM(pc.sub_metering_1 + pc.sub_metering_2 + pc.sub_metering_3) / NULLIF(SUM(pc.global_active_power * 1000 / 60), 0) AS submetering_efficiency
         FROM power_consumption pc
                  JOIN power_factor_calc pf ON pc.date_time = pf.date_time

         GROUP BY DATE_TRUNC('hour', pc.date_time)
     )
SELECT
    hour,
    avg_active_power,
    avg_reactive_power,
    avg_power_factor,
    submetering_efficiency,
    CASE
        WHEN avg_power_factor > 0.95 THEN 'Excellent'
        WHEN avg_power_factor > 0.9 THEN 'Good'
        WHEN avg_power_factor > 0.8 THEN 'Fair'
        ELSE 'Poor'
        END AS power_factor_category,
    CASE
        WHEN submetering_efficiency > 0.9 THEN 'Highly Efficient'
        WHEN submetering_efficiency > 0.7 THEN 'Moderately Efficient'
        WHEN submetering_efficiency > 0.5 THEN 'Somewhat Efficient'
        ELSE 'Inefficient'
        END AS submetering_efficiency_category
FROM efficiency_metrics
ORDER BY hour;


-- Usage: View efficiency analysis results
SELECT * FROM vw_efficiency_analysis LIMIT 24;

CREATE OR REPLACE VIEW vw_submetering_distribution AS
SELECT
    DATE_TRUNC('day', date_time) AS day,
    AVG(sub_metering_1) AS avg_sub1,
    AVG(sub_metering_2) AS avg_sub2,
    AVG(sub_metering_3) AS avg_sub3,
    AVG(global_active_power * 1000 / 60 - (sub_metering_1 + sub_metering_2 + sub_metering_3)) AS avg_sub_other
FROM power_consumption
GROUP BY DATE_TRUNC('day', date_time)
ORDER BY day;


-- Usage: View daily submetering distribution
SELECT * FROM vw_submetering_distribution LIMIT 10;


CREATE OR REPLACE FUNCTION calculate_submetering_percentage()
    RETURNS TABLE (
                      sub_metering TEXT,
                      percentage FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH total_consumption AS (
            SELECT
                SUM(sub_metering_1) AS total_sub1,
                SUM(sub_metering_2) AS total_sub2,
                SUM(sub_metering_3) AS total_sub3,
                SUM(global_active_power * 1000 / 60 - (sub_metering_1 + sub_metering_2 + sub_metering_3)) AS total_sub_other
            FROM power_consumption
        )
        SELECT 'Sub_metering_1' AS sub_metering,
               (total_sub1 / NULLIF(total_sub1 + total_sub2 + total_sub3 + total_sub_other, 0)) * 100 AS percentage
        FROM total_consumption
        UNION ALL
        SELECT 'Sub_metering_2',
               (total_sub2 / NULLIF(total_sub1 + total_sub2 + total_sub3 + total_sub_other, 0)) * 100
        FROM total_consumption
        UNION ALL
        SELECT 'Sub_metering_3',
               (total_sub3 / NULLIF(total_sub1 + total_sub2 + total_sub3 + total_sub_other, 0)) * 100
        FROM total_consumption
        UNION ALL
        SELECT 'Other',
               (total_sub_other / NULLIF(total_sub1 + total_sub2 + total_sub3 + total_sub_other, 0)) * 100
        FROM total_consumption;
END;
$$ LANGUAGE plpgsql;


-- Usage: Calculate submetering percentage contribution
SELECT * FROM calculate_submetering_percentage();


CREATE OR REPLACE VIEW vw_hourly_submetering_pattern AS
SELECT
    EXTRACT(HOUR FROM date_time) AS hour,
    AVG(sub_metering_1) AS avg_sub1,
    AVG(sub_metering_2) AS avg_sub2,
    AVG(sub_metering_3) AS avg_sub3,
    AVG(global_active_power * 1000 / 60 - (sub_metering_1 + sub_metering_2 + sub_metering_3)) AS avg_sub_other
FROM power_consumption
GROUP BY EXTRACT(HOUR FROM date_time)
ORDER BY hour;


-- Usage: View hourly submetering pattern
SELECT * FROM vw_hourly_submetering_pattern;

CREATE OR REPLACE FUNCTION analyze_submetering_correlations()
    RETURNS TABLE (
                      correlation_pair TEXT,
                      correlation_coefficient FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        SELECT 'Sub1 vs Sub2' AS correlation_pair,
               corr(sub_metering_1, sub_metering_2) AS correlation_coefficient
        FROM power_consumption
        UNION ALL
        SELECT 'Sub1 vs Sub3',
               corr(sub_metering_1, sub_metering_3)
        FROM power_consumption
        UNION ALL
        SELECT 'Sub2 vs Sub3',
               corr(sub_metering_2, sub_metering_3)
        FROM power_consumption
        UNION ALL
        SELECT 'Sub1 vs Total',
               corr(sub_metering_1, global_active_power)
        FROM power_consumption
        UNION ALL
        SELECT 'Sub2 vs Total',
               corr(sub_metering_2, global_active_power)
        FROM power_consumption
        UNION ALL
        SELECT 'Sub3 vs Total',
               corr(sub_metering_3, global_active_power)
        FROM power_consumption;
END;
$$ LANGUAGE plpgsql;


-- Usage: Analyze submetering correlations
SELECT * FROM analyze_submetering_correlations();

CREATE OR REPLACE VIEW vw_submetering_efficiency AS
WITH daily_consumption AS (
    SELECT
        DATE_TRUNC('day', date_time) AS day,
        AVG(sub_metering_1) AS avg_sub1,
        AVG(sub_metering_2) AS avg_sub2,
        AVG(sub_metering_3) AS avg_sub3,
        AVG(global_active_power * 1000 / 60 - (sub_metering_1 + sub_metering_2 + sub_metering_3)) AS avg_sub_other,
        AVG(global_active_power * 1000 / 60) AS avg_total
    FROM power_consumption
    GROUP BY DATE_TRUNC('day', date_time)
)
SELECT
    day,
    avg_sub1 / NULLIF(avg_total, 0) AS efficiency_sub1,
    avg_sub2 / NULLIF(avg_total, 0) AS efficiency_sub2,
    avg_sub3 / NULLIF(avg_total, 0) AS efficiency_sub3,
    avg_sub_other / NULLIF(avg_total, 0) AS efficiency_other,
    (avg_sub1 + avg_sub2 + avg_sub3) / NULLIF(avg_total, 0) AS total_known_efficiency
FROM daily_consumption
ORDER BY day;

-- Usage: View submetering efficiency
SELECT * FROM vw_submetering_efficiency LIMIT 10;

CREATE OR REPLACE VIEW vw_anomaly_dashboard_advanced AS
WITH
    zscore_anomalies AS (
        SELECT * FROM detect_anomalies_zscore(3) LIMIT 5
    ),
    moving_avg_anomalies AS (
        SELECT * FROM detect_anomalies_moving_avg(24, 2) LIMIT 5
    ),
    seasonal_anomalies AS (
        SELECT * FROM detect_seasonal_anomalies(3) LIMIT 5
    ),
    sudden_changes AS (
        SELECT * FROM detect_sudden_changes(5) LIMIT 5
    )
SELECT 'Z-Score' AS method, date_time, global_active_power, zscore AS metric FROM zscore_anomalies
UNION ALL
SELECT 'Moving Average' AS method, date_time, global_active_power, deviation AS metric FROM moving_avg_anomalies
UNION ALL
SELECT 'Seasonal' AS method, date_time, global_active_power, deviation AS metric FROM seasonal_anomalies
UNION ALL
SELECT 'Sudden Change' AS method, date_time, global_active_power, change AS metric FROM sudden_changes
ORDER BY method, metric DESC;


SELECT * FROM vw_anomaly_dashboard_advanced;


CREATE OR REPLACE VIEW vw_efficiency_analysis AS
WITH power_factor_calc AS (
    SELECT * FROM calculate_power_factor()
),
     efficiency_metrics AS (
         SELECT
             DATE_TRUNC('hour', pc.date_time) AS hour,
             AVG(pc.global_active_power) AS avg_active_power,
             AVG(pc.global_reactive_power) AS avg_reactive_power,
             AVG(pf.power_factor) AS avg_power_factor,
             SUM(pc.sub_metering_1 + pc.sub_metering_2 + pc.sub_metering_3) / NULLIF(SUM(pc.global_active_power * 1000 / 60), 0) AS submetering_efficiency
         FROM power_consumption pc
                  JOIN power_factor_calc pf ON pc.date_time = pf.date_time
         GROUP BY DATE_TRUNC('hour', pc.date_time)
     )
SELECT
    hour,
    avg_active_power,
    avg_reactive_power,
    avg_power_factor,
    submetering_efficiency,
    CASE
        WHEN avg_power_factor > 0.95 THEN 'Excellent'
        WHEN avg_power_factor > 0.9 THEN 'Good'
        WHEN avg_power_factor > 0.8 THEN 'Fair'
        ELSE 'Poor'
        END AS power_factor_category,
    CASE
        WHEN submetering_efficiency > 0.9 THEN 'Highly Efficient'
        WHEN submetering_efficiency > 0.7 THEN 'Moderately Efficient'
        WHEN submetering_efficiency > 0.5 THEN 'Somewhat Efficient'
        ELSE 'Inefficient'
        END AS submetering_efficiency_category
FROM efficiency_metrics
ORDER BY hour;

SELECT * FROM vw_efficiency_analysis LIMIT 24;


CREATE OR REPLACE FUNCTION identify_low_efficiency_periods(
    power_factor_threshold FLOAT,
    efficiency_threshold FLOAT
)
    RETURNS TABLE (
                      start_time TIMESTAMP WITH TIME ZONE,
                      end_time TIMESTAMP WITH TIME ZONE,
                      avg_power_factor FLOAT,
                      avg_submetering_efficiency FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH low_efficiency_periods AS (
            SELECT
                hour,
                em.avg_power_factor,
                em.submetering_efficiency,
                LAG(hour) OVER (ORDER BY hour) AS prev_hour
            FROM vw_efficiency_analysis em
            WHERE em.avg_power_factor < power_factor_threshold OR em.submetering_efficiency < efficiency_threshold
        ),
             grouped_periods AS (
                 SELECT
                     hour,
                     em.avg_power_factor,
                     em.submetering_efficiency,
                     SUM(CASE WHEN hour - prev_hour > INTERVAL '1 hour' THEN 1 ELSE 0 END) OVER (ORDER BY hour) AS group_id
                 FROM low_efficiency_periods em
             )
        SELECT
            MIN(hour) AS start_time,
            MAX(hour) + INTERVAL '1 hour' AS end_time,
            AVG(em.avg_power_factor) AS avg_power_factor,
            AVG(em.submetering_efficiency) AS avg_submetering_efficiency
        FROM grouped_periods em
        GROUP BY group_id
        ORDER BY start_time;
END;
$$ LANGUAGE plpgsql;


-- Usage: Identify periods of low efficiency (power factor < 0.8 or submetering efficiency < 0.6)
SELECT * FROM identify_low_efficiency_periods(0.8, 0.6);

CREATE OR REPLACE VIEW vw_efficiency_recommendations AS
WITH efficiency_summary AS (
    SELECT
        AVG(avg_power_factor) AS overall_avg_power_factor,
        AVG(submetering_efficiency) AS overall_avg_submetering_efficiency,
        MIN(avg_power_factor) AS min_power_factor,
        MIN(submetering_efficiency) AS min_submetering_efficiency
    FROM vw_efficiency_analysis
),
     low_efficiency_count AS (
         SELECT COUNT(*) AS low_efficiency_periods
         FROM identify_low_efficiency_periods(0.8, 0.6)
     )
SELECT
    overall_avg_power_factor,
    overall_avg_submetering_efficiency,
    min_power_factor,
    min_submetering_efficiency,
    low_efficiency_periods,
    CASE
        WHEN overall_avg_power_factor < 0.9 THEN 'Consider installing power factor correction equipment'
        ELSE 'Power factor is generally good'
        END AS power_factor_recommendation,
    CASE
        WHEN overall_avg_submetering_efficiency < 0.7 THEN 'Investigate energy loss in non-submetered appliances'
        ELSE 'Submetering efficiency is acceptable'
        END AS submetering_recommendation,
    CASE
        WHEN low_efficiency_periods > 10 THEN 'Frequent low efficiency periods detected. Consider energy audit.'
        WHEN low_efficiency_periods > 0 THEN 'Some low efficiency periods detected. Monitor and investigate causes.'
        ELSE 'No significant low efficiency periods detected.'
        END AS low_efficiency_recommendation
FROM efficiency_summary, low_efficiency_count;

-- Usage: View efficiency recommendations
SELECT * FROM vw_efficiency_recommendations;

CREATE OR REPLACE FUNCTION analyze_efficiency_trend(
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE
)
    RETURNS TABLE (
                      date DATE,
                      avg_power_factor FLOAT,
                      avg_submetering_efficiency FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            DATE_TRUNC('day', hour)::DATE AS date,
            AVG(em.avg_power_factor) AS avg_power_factor,
            AVG(em.submetering_efficiency) AS avg_submetering_efficiency
        FROM vw_efficiency_analysis em
        WHERE hour::DATE BETWEEN start_date::DATE AND end_date::DATE
        GROUP BY DATE_TRUNC('day', hour)::DATE
        ORDER BY date;
END;
$$ LANGUAGE plpgsql;

-- Usage: Analyze efficiency trend for the last 30 days
SELECT * FROM analyze_efficiency_trend(CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE);

CREATE OR REPLACE FUNCTION identify_submetering_peaks(threshold_percentile FLOAT)
    RETURNS TABLE (
                      sub_metering TEXT,
                      date_time TIMESTAMP WITH TIME ZONE,
                      consumption FLOAT
                  ) AS $$
BEGIN
    RETURN QUERY
        WITH percentiles AS (
            SELECT
                        PERCENTILE_CONT(threshold_percentile) WITHIN GROUP (ORDER BY pc.sub_metering_1) AS threshold1,
                        PERCENTILE_CONT(threshold_percentile) WITHIN GROUP (ORDER BY pc.sub_metering_2) AS threshold2,
                        PERCENTILE_CONT(threshold_percentile) WITHIN GROUP (ORDER BY pc.sub_metering_3) AS threshold3,
                        PERCENTILE_CONT(threshold_percentile) WITHIN GROUP (ORDER BY (pc.global_active_power * 1000 / 60 - (pc.sub_metering_1 + pc.sub_metering_2 + pc.sub_metering_3))) AS threshold_other
            FROM power_consumption pc
        )
        SELECT 'Sub_metering_1' AS sub_metering, pc.date_time, pc.sub_metering_1 AS consumption
        FROM power_consumption pc, percentiles
        WHERE pc.sub_metering_1 > percentiles.threshold1
        UNION ALL
        SELECT 'Sub_metering_2', pc.date_time, pc.sub_metering_2
        FROM power_consumption pc, percentiles
        WHERE pc.sub_metering_2 > percentiles.threshold2
        UNION ALL
        SELECT 'Sub_metering_3', pc.date_time, pc.sub_metering_3
        FROM power_consumption pc, percentiles
        WHERE pc.sub_metering_3 > percentiles.threshold3
        UNION ALL
        SELECT 'Other', pc.date_time, (pc.global_active_power * 1000 / 60 - (pc.sub_metering_1 + pc.sub_metering_2 + pc.sub_metering_3))
        FROM power_consumption pc, percentiles
        WHERE (pc.global_active_power * 1000 / 60 - (pc.sub_metering_1 + pc.sub_metering_2 + pc.sub_metering_3)) > percentiles.threshold_other
        ORDER BY consumption DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage: Identify peak consumption periods (top 5%)?.hf dsxcvgh
SELECT * FROM identify_submetering_peaks(0.95) LIMIT 20;




