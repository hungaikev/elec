# Python Script Documentation

This document provides an overview of the main functions in the Python script used for data processing and database setup in the household electric power consumption analysis.

## Database Setup Function

```python
def setup_database():
```

**Purpose:** This function sets up the PostgreSQL database with the necessary extensions and tables for the power consumption data.

**Key Actions:**
1. Enables required PostgreSQL extensions (TimescaleDB, UUID-OSSP, PostGIS).
2. Creates the `power_consumption` table with appropriate columns.
3. Sets up partitioning for the `power_consumption` table by year.
4. Creates indexes for optimizing queries.

**Returns:**
- `True` if setup is successful
- `False` if an error occurs

## Data Cleaning Function

```python
def clean_data(file_path):
```

**Purpose:** This function reads the CSV file, cleans the data, and prepares it for insertion into the database.

**Parameters:**
- `file_path`: Path to the CSV file containing the power consumption data

**Key Actions:**
1. Reads the CSV file into a pandas DataFrame.
2. Combines 'Date' and 'Time' columns into a single 'date_time' column.
3. Replaces '?' with NaN values.
4. Standardizes column names.
5. Converts numeric columns to float type.
6. Handles missing data through interpolation and forward/backward filling.
7. Ensures proper data types for all columns.

**Returns:**
- A cleaned pandas DataFrame if successful
- `None` if an error occurs

## Data Validation Function

```python
def validate_data(df):
```

**Purpose:** This function performs validation checks on the cleaned data.

**Parameters:**
- `df`: pandas DataFrame containing the cleaned data

**Key Actions:**
1. Checks for negative values in power columns.
2. Validates that voltage is within a reasonable range (100-300V).
3. Logs warnings for out-of-range values.
4. Interpolates any out-of-range voltage values.

**Returns:** The validated DataFrame

## Data Insertion Function

```python
def insert_data(df):
```

**Purpose:** This function inserts the cleaned and validated data into the PostgreSQL database.

**Parameters:**
- `df`: pandas DataFrame containing the cleaned and validated data

**Key Actions:**
1. Establishes a connection to the PostgreSQL database.
2. Truncates the existing `power_consumption` table if it exists.
3. Inserts data in batches of 1000 rows for efficient processing.
4. Logs the progress of data insertion.

## Main Function

```python
def main():
```

**Purpose:** This is the main execution function that orchestrates the entire process.

**Key Actions:**
1. Calls `setup_database()` to ensure the database is properly configured.
2. Calls `clean_data()` to process the input CSV file.
3. Calls `insert_data()` to populate the database with the cleaned data.
4. Handles any exceptions that occur during the process and logs appropriate messages.

## Utility Functions

### Environment Variable Loading

```python
load_dotenv()
```

**Purpose:** Loads environment variables from a .env file, used for database connection parameters.

### Logging Configuration

```python
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
```

**Purpose:** Sets up logging to track the progress and any issues during script execution.

## Script Execution

The script uses the following pattern for execution:

```python
if __name__ == "__main__":
    main()
```

This ensures that the `main()` function is only called if the script is run directly, not if it's imported as a module.