# SQL Queries Documentation

This document provides an overview of the main SQL queries used in the household electric power consumption analysis.

## Basic Statistics View

```sql
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
```

This view provides a quick overview of the dataset, including:
- Total number of records
- Date range of the data
- Average, maximum, and minimum global active power
- Average voltage and global intensity

## Hourly Power Consumption View

```sql
CREATE OR REPLACE VIEW vw_hourly_power_consumption AS
SELECT
    DATE_TRUNC('hour', date_time) as hour,
    AVG(global_active_power) as avg_power
FROM power_consumption
GROUP BY DATE_TRUNC('hour', date_time)
ORDER BY hour;
```

This view aggregates power consumption data by hour, allowing for analysis of daily patterns.

## Daily Power Consumption View

```sql
CREATE OR REPLACE VIEW vw_daily_power_consumption AS
SELECT
    DATE_TRUNC('day', date_time) as day,
    AVG(global_active_power) as avg_power,
    MAX(global_active_power) as max_power,
    MIN(global_active_power) as min_power
FROM power_consumption
GROUP BY DATE_TRUNC('day', date_time)
ORDER BY day;
```

This view provides daily aggregates of power consumption, including average, maximum, and minimum power for each day.

## Anomaly Detection Function (Z-Score Method)

```sql
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
```

This function detects anomalies in power consumption using the Z-score method. It identifies data points that are a specified number of standard deviations away from the mean.

## Forecasting Function (Simple Moving Average)

```sql
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
```

This function implements a simple moving average forecasting method. It predicts future power consumption based on the average of a specified number of preceding days.

## Efficiency Analysis View

```sql
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
```

This view calculates various efficiency metrics, including power factor and submetering efficiency. It also categorizes the efficiency levels for easy interpretation.

## Weighted Moving Average Forecast

```sql
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
```

This function implements a weighted moving average forecast. It gives more weight to recent data points, potentially improving forecast accuracy for time series with recent trends.

## Exponential Smoothing Forecast

```sql
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
```

This function implements exponential smoothing for forecasting. It uses a smoothing factor (alpha) to give more weight to recent observations, making it adaptable to changing trends.

## Anomaly Detection Using Moving Average

```sql
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
```

This function detects anomalies by comparing each data point to a moving average. It flags points that deviate significantly from the moving average, allowing for the detection of local anomalies.

## Seasonal Anomaly Detection

```sql
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
```

This function detects seasonal anomalies by comparing each data point to the average for the same month, day of week, and hour. It's useful for identifying unusual consumption patterns while accounting for regular seasonal variations.

## Efficiency Recommendations View

```sql
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
```

This view generates efficiency recommendations based on power factor, submetering efficiency, and the frequency of low efficiency periods. It provides actionable insights for improving overall energy efficiency.