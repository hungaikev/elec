import os
import pandas as pd
import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_values
from dotenv import load_dotenv
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Load environment variables
load_dotenv()

# Database connection parameters
db_params = {
    "dbname": os.getenv("DB_NAME", "power_consumption_db"),
    "user": os.getenv("DB_USER", "poweruser"),
    "password": os.getenv("DB_PASSWORD", "powerpassword"),
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432")
}


def create_connection():
    try:
        conn = psycopg2.connect(**db_params)
        return conn
    except psycopg2.Error as e:
        logging.error(f"Unable to connect to the database: {e}")
        raise


def insert_data(conn, df, table_name, batch_size=10000):
    columns = df.columns.tolist()
    column_str = ', '.join(f'"{col}"' for col in columns)
    insert_stmt = f"INSERT INTO {table_name} ({column_str}) VALUES %s"

    with conn.cursor() as cur:
        for start in range(0, len(df), batch_size):
            end = start + batch_size
            batch = df.iloc[start:end]
            try:
                values = [tuple(x) for x in batch.to_numpy()]
                execute_values(cur, insert_stmt, values)
                conn.commit()
                logging.info(f"Inserted batch of {len(batch)} rows")
            except psycopg2.Error as e:
                conn.rollback()
                logging.error(f"Error inserting batch: {e}")
                raise


def process_data(df):
    # Replace '?' with NaN
    df = df.replace('?', pd.NA)

    # Convert columns to appropriate data types
    numeric_columns = ['Global_active_power', 'Global_reactive_power', 'Voltage',
                       'Global_intensity', 'Sub_metering_1', 'Sub_metering_2', 'Sub_metering_3']
    for col in numeric_columns:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    # Combine Date and Time columns into a single datetime column
    df['date_time'] = pd.to_datetime(df['Date'] + ' ' + df['Time'], format='%d/%m/%Y %H:%M:%S')

    # Drop original Date and Time columns
    df = df.drop(['Date', 'Time'], axis=1)

    # Rename columns to match database schema
    df = df.rename(columns={
        'Global_active_power': 'global_active_power',
        'Global_reactive_power': 'global_reactive_power',
        'Voltage': 'voltage',
        'Global_intensity': 'global_intensity',
        'Sub_metering_1': 'sub_metering_1',
        'Sub_metering_2': 'sub_metering_2',
        'Sub_metering_3': 'sub_metering_3',
        'date_time': 'date_time'
    })

    return df


def ingest_data(file_path):
    try:
        # Read the CSV file without specifying dtypes
        df = pd.read_csv(file_path, sep=';', low_memory=False)
        logging.info(f"Successfully read CSV file: {file_path}")

        # Process the data
        df = process_data(df)
        logging.info("Data processing completed")

        # Print column names for verification
        logging.info(f"DataFrame columns: {df.columns.tolist()}")

        # Create a database connection
        conn = create_connection()

        try:
            # Insert data into the database
            insert_data(conn, df, 'power_consumption')
            logging.info("Data ingestion completed successfully")
        finally:
            conn.close()

    except Exception as e:
        logging.error(f"An error occurred during data ingestion: {e}")
        raise


if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(script_dir, 'household_power_consumption.csv')

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"The file {file_path} does not exist.")

    ingest_data(file_path)
