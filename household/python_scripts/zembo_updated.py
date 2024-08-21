import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv
import logging
import unittest

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Database connection parameters loaded from environment variables
db_params = {
    "dbname": os.getenv("DB_NAME", "power_consumption_db"),
    "user": os.getenv("DB_USER", "poweruser"),
    "password": os.getenv("DB_PASSWORD", "powerpassword"),
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432")
}


def setup_database():
    try:
        engine = create_engine(
            f"postgresql://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['dbname']}")

        with engine.connect() as conn:
            # Enable extensions
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS timescaledb"))
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""))
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis_topology"))
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis_raster"))

            # Drop existing table and related objects
            conn.execute(text("DROP TABLE IF EXISTS power_consumption CASCADE"))

            # Create the power_consumption table with TIMESTAMPTZ for date_time
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS power_consumption (
                    date_time TIMESTAMPTZ NOT NULL,
                    global_active_power FLOAT,
                    global_reactive_power FLOAT,
                    voltage FLOAT,
                    global_intensity FLOAT,
                    sub_metering_1 FLOAT,
                    sub_metering_2 FLOAT,
                    sub_metering_3 FLOAT
                ) PARTITION BY RANGE (date_time)
            """))
            logging.info("Table power_consumption created successfully.")

            # Create partitions
            for year in range(2006, 2012):
                conn.execute(text(f"""
                    CREATE TABLE IF NOT EXISTS power_consumption_y{year}
                    PARTITION OF power_consumption
                    FOR VALUES FROM ('{year}-01-01') TO ('{year + 1}-01-01')
                """))

            # Create indexes
            conn.execute(
                text("CREATE INDEX IF NOT EXISTS idx_date_power ON power_consumption (date_time, global_active_power)"))
            conn.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_high_power ON power_consumption (date_time, global_active_power) WHERE global_active_power > 5"))

            logging.info("Database setup completed successfully.")

    except Exception as e:
        logging.error(f"Error setting up database: {e}")
        return False  # Return False if setup fails

    return True  # Return True if setup succeeds


def clean_data(file_path):
    try:
        # Load data from CSV
        df = pd.read_csv(file_path, sep=';', low_memory=False)

        # Combine 'Date' and 'Time' columns into a single 'date_time' column
        df['date_time'] = pd.to_datetime(df['Date'] + ' ' + df['Time'], dayfirst=True, format='%d/%m/%Y %H:%M:%S',
                                         utc=True)

        # Drop the original 'Date' and 'Time' columns
        df.drop(columns=['Date', 'Time'], inplace=True)

        # Replace '?' with NaN
        df.replace('?', np.nan, inplace=True)

        # Standardize column names to lowercase and remove spaces to ensure consistency
        df.columns = df.columns.str.strip().str.lower()

        # Mapping the columns to the correct format as per the expected schema
        column_mapping = {
            'global_active_power': 'global_active_power',
            'global_reactive_power': 'global_reactive_power',
            'voltage': 'voltage',
            'global_intensity': 'global_intensity',
            'sub_metering_1': 'sub_metering_1',
            'sub_metering_2': 'sub_metering_2',
            'sub_metering_3': 'sub_metering_3'
        }

        df.rename(columns=column_mapping, inplace=True)

        # Check that all expected columns are present
        expected_columns = list(column_mapping.values()) + ['date_time']
        if not all(col in df.columns for col in expected_columns):
            missing_cols = [col for col in expected_columns if col not in df.columns]
            raise ValueError(f"Missing columns in the dataset: {missing_cols}")

        # Ensure that numeric columns are converted to float
        numeric_columns = ['global_active_power', 'global_reactive_power', 'voltage',
                           'global_intensity', 'sub_metering_1', 'sub_metering_2', 'sub_metering_3']

        df[numeric_columns] = df[numeric_columns].apply(pd.to_numeric, errors='coerce')

        # Handle missing data: interpolate and then forward/backward fill
        df[numeric_columns] = df[numeric_columns].interpolate(method='linear')
        df[numeric_columns] = df[numeric_columns].ffill()
        df[numeric_columns] = df[numeric_columns].bfill()

        # Ensure the date_time column is properly set as datetime with timezone
        df['date_time'] = pd.to_datetime(df['date_time'], utc=True)

        # Ensure that each column has the correct type
        df = df.astype({
            'date_time': 'datetime64[ns, UTC]',
            'global_active_power': 'float64',
            'global_reactive_power': 'float64',
            'voltage': 'float64',
            'global_intensity': 'float64',
            'sub_metering_1': 'float64',
            'sub_metering_2': 'float64',
            'sub_metering_3': 'float64'
        })

        # Validate the data
        validate_data(df)

        # Print the column types to confirm the changes
        logging.info(df.dtypes)

        logging.info("Data cleaned successfully.")
        return df

    except Exception as e:
        logging.error(f"Error cleaning data: {e}")
        return None


def validate_data(df):
    # Example validation: Check for negative values in power columns
    if (df[['global_active_power', 'global_reactive_power']] < 0).any().any():
        raise ValueError("Negative values found in power columns")

    # Example validation: Check if voltage is within a reasonable range
    if not df['voltage'].between(100, 300).all():
        # Log the number of out-of-range voltage values
        out_of_range_count = (~df['voltage'].between(100, 300)).sum()
        logging.warning(f"Voltage values out of range: {out_of_range_count} occurrences.")
        # Optionally, set these to NaN and interpolate
        df.loc[~df['voltage'].between(100, 300), 'voltage'] = np.nan
        df['voltage'].interpolate(method='linear', inplace=True)
        df.ffill(inplace=True)
        df.bfill(inplace=True)

    logging.info("Data validation passed.")
    return df


def insert_data(df):
    try:
        engine = create_engine(
            f"postgresql://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['dbname']}"
        )

        # Ensure the table exists before attempting to truncate
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'power_consumption'
                );
            """))
            if result.scalar():
                conn.execute(text("TRUNCATE TABLE power_consumption"))
                logging.info("Table power_consumption truncated.")
            else:
                logging.warning("Table power_consumption does not exist. Skipping truncation.")

        # Insert data in batches of 1000
        batch_size = 1000
        total_rows = len(df)
        for start in range(0, total_rows, batch_size):
            end = min(start + batch_size, total_rows)
            batch_df = df.iloc[start:end]
            batch_df.to_sql('power_consumption', engine, if_exists='append', index=False, method='multi',
                            chunksize=batch_size)
            logging.info(f"Inserted rows {start + 1} to {end} out of {total_rows}")

        logging.info("Data insertion completed successfully.")

    except Exception as e:
        logging.error(f"Error inserting data: {e}")


def main():
    try:
        logging.info("Setting up database...")
        if not setup_database():
            raise Exception("Database setup failed.")
    except Exception as e:
        logging.error(f"Error during database setup: {e}")
        return

    try:
        logging.info("Cleaning data...")
        script_dir = os.path.dirname(os.path.abspath(__file__))
        file_path = os.path.join(script_dir, 'household_power_consumption.csv')
        df = clean_data(file_path)
        if df is None:
            raise ValueError("Data cleaning failed.")
    except Exception as e:
        logging.error(f"Error during data cleaning: {e}")
        return

    try:
        logging.info("Inserting data...")
        insert_data(df)
    except Exception as e:
        logging.error(f"Error during data insertion: {e}")
        return

    logging.info("All operations completed successfully.")


if __name__ == "__main__":
    main()
