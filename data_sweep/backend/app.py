import traceback
from flask import Flask, request, jsonify, send_file
from statistics import mode, StatisticsError
import pandas as pd
import numpy as np
import io
from datetime import datetime

app = Flask(__name__)

def to_title_case(string):
    return ' '.join([word.capitalize() if len(word) > 1 else word.upper() for word in string.split(' ')])

def to_sentence_case(string):
    if not string:
        return string
    return string[0].upper() + string[1:].lower()

def apply_letter_casing(data, columns, casing_selections):
    # Start from the second row (index 1) to skip the header
    for i in range(len(columns)):
        casing = casing_selections[i]
        for j in range(1, len(data)):  # Start loop from 1 to skip the header
            value = data[j][i]
            if isinstance(value, str):
                if casing == 'UPPERCASE':
                    data[j][i] = value.upper()
                elif casing == 'lowercase':
                    data[j][i] = value.lower()
                elif casing == 'Title Case':
                    data[j][i] = to_title_case(value)
                elif casing == 'Sentence case':
                    data[j][i] = to_sentence_case(value)
    
    return data


def is_valid_date(value):
    try:
        parsed_date = datetime.strptime(value, "%Y-%m-%d")
        return True
    except ValueError:
        return False

def reformat_date(data, date_format, classifications):
    # Define format mappings for supported date formats
    format_mappings = {
        'mm/dd/yyyy': '%m/%d/%Y',
        'dd/mm/yyyy': '%d/%m/%Y',
        'yyyy/mm/dd': '%Y/%m/%d',
    }
    print(f"reformat_date: Selected Format - {date_format}")

    # Check if the date format is supported
    if date_format not in format_mappings:
        raise ValueError(f"Unsupported date format: {date_format}")

    # Get the target format string
    target_format_str = format_mappings[date_format]
    print(f"Target Format for output: {target_format_str}")

    # Identify indices of date columns based on classifications
    date_column_indices = [
        index for index, classification in enumerate(classifications)
        if classification[3] == 1  # 1 indicates it's a date column
    ]

    # Iterate over rows and only process values in date columns
    for row in data:
        for col_index in date_column_indices:
            value = row[col_index]
            if isinstance(value, str):  # Ensure it's a string
                print(f"Original Value in Date Column: {value}")
                parsed_date = None

                # Attempt parsing with each available format
                for fmt in format_mappings.values():
                    try:
                        parsed_date = datetime.strptime(value, fmt)
                        print(f"Parsed Date with format '{fmt}': {parsed_date}")
                        break  # Stop if a format successfully parses
                    except ValueError:
                        continue  # Continue if parsing fails

                # Reformat if parsing succeeded
                if parsed_date:
                    reformatted_date = parsed_date.strftime(target_format_str)
                    print(f"Reformatted Date: {reformatted_date}")
                    row[col_index] = reformatted_date
                else:
                    print(f"Skipping value '{value}' due to unrecognized date format.")

    return data


def apply_date_format(data, columns, date_format, classifications):
    # Define format mappings for supported date formats
    format_mappings = {
        'mm/dd/yyyy': '%m/%d/%Y',
        'dd/mm/yyyy': '%d/%m/%Y',
        'yyyy/mm/dd': '%Y/%m/%d',
    }

    # Check if the date format is supported
    if date_format not in format_mappings:
        raise ValueError(f"Unsupported date format: {date_format}")

    # Get the corresponding format string for parsing and formatting
    target_format_str = format_mappings[date_format]
    print(f"Target format for output: {target_format_str}")

    # Loop over columns and rows to format dates in the specified columns
    for i in range(len(columns)):
        # Check if the column is classified as a date column
        if classifications[i][3] == 1:  # 1 indicates it is a date column
            for j in range(len(data)):
                value = data[j][i]

                # Ensure the value is a string (only try to parse string dates)
                if isinstance(value, str):
                    # Try parsing the date using multiple formats
                    parsed_date = None
                    for fmt in format_mappings.values():
                        try:
                            parsed_date = datetime.strptime(value, fmt)
                            break  # Stop if parsing is successful
                        except ValueError:
                            continue
                    
                    # If parsing was successful, format the date to the target format
                    if parsed_date:
                        data[j][i] = parsed_date.strftime(target_format_str)
                    else:
                        print(f"Invalid date format for value: {value}")

    return data

def count_non_numeric(data, column_index):
    non_numeric_count = 0
    for row in data[1:]:  # Skip header row
        value = row[column_index]
        # Skip None, empty strings, and NaN values
        if value is None or value == " " or pd.isna(value) or value =="":
            continue
        # Check if the value is non-numeric
        try:
            float(value)
        except (ValueError, TypeError):
            non_numeric_count += 1

    return non_numeric_count  # Return the count as an integer

def detect_invalid_dates(data, column_index):
    # Initialize the count of invalid dates
    invalid_dates_count = 0

    # Define valid date formats
    valid_date_formats = [
        '%m-%d-%y',   # MM-DD-YY
        '%d-%m-%y',   # DD-MM-YY
        '%Y-%m-%d',   # YYYY-MM-DD
        '%m/%d/%Y',   # MM-DD-YYYY
        '%d/%m/%Y',   # DD-MM-YYYY
        '%b %d, %Y',  # Jan 01, 2020 (month abbreviation, comma)
        '%b. %d, %Y', # Jan. 01, 2020 (month abbreviation, period, comma)
        '%B %d, %Y',  # February 01, 2004 (full month name, comma)
    ]

    # Iterate through each row in the data, skipping the header row
    for row in data[1:]:  # Assuming data[0] is the header row
        date_value = row[column_index]

        # Skip missing values
        if date_value is None or date_value == "" or date_value == " ":
            continue

        is_valid = False
        for date_format in valid_date_formats:
            try:
                # Try parsing the date with the current format
                datetime.strptime(str(date_value), date_format)
                is_valid = True
                break  # Stop checking other formats if valid
            except ValueError:
                continue  # Try the next date format

        # If the date is invalid, increment the count
        if not is_valid:
            invalid_dates_count += 1

    # Return the count of invalid dates for the specified column
    return invalid_dates_count

def detect_issues(data, columns, classifications):
    issues = {}
    missingValuesCount = 0
    
    for i in range(len(columns)):
        column_issues = []
        column_index = i
        column_data = [row[column_index] for row in data[1:]]  # Skip header row

        # Count missing values in the column
        missing_count = sum(1 for value in column_data if pd.isna(value) or value == " " or value == "")
        missingValuesCount += missing_count
        if missing_count > 0:
            column_issues.append(f"Missing Values")

        if classifications[i][0] == 1:  # Numeric column
            non_numeric_count = count_non_numeric(data, column_index)
            if non_numeric_count > 0:
                column_issues.append(f"Non-Numeric Values")

        
        elif classifications[i][3] == 1:  # Date column
            invalid_dates_count = detect_invalid_dates(data, column_index)
            if invalid_dates_count >= 0:
                column_issues.append(f"Invalid Dates")

        if column_issues:
            issues[columns[i]] = column_issues

    return issues

def map_categorical_values(data, column, unique_values, standard_format):
    print("Function Invoked: map_categorical_values")
    
    # Print the inputs received
    print(f"Data received: {data}")
    print(f"Column to map: {column}")
    print(f"Unique values received: {unique_values}")
    print(f"Standard format provided: {standard_format}")

    # Prepare the data for DataFrame creation
    headers = data[0] if isinstance(data[0], list) else []
    data_rows = data[1:] if len(data) > 1 else []

    # Convert headers and target column name to uppercase for consistency
    headers = [header.upper() for header in headers]
    column = column.upper()

    # Create the DataFrame with uppercase column names
    df = pd.DataFrame(data_rows, columns=headers)
    print("DataFrame created from input data with uppercase column names:")
    print(df)

    # Create the mapping dictionary and print it
    category_mapping = dict(zip(unique_values, standard_format))
    print("Category mapping dictionary created:")
    print(category_mapping)

    # Apply mapping if the column exists in the DataFrame
    if column in df.columns:
        df[column] = df[column].map(category_mapping)
        print(f"DataFrame after applying mapping to column '{column}':")
    else:
        print(f"Error: Column '{column}' not found in DataFrame.")
    
    print(df)

    # Prepare the result for returning and print it
    result = [df.columns.tolist()] + df.values.tolist()
    print("Final result to be returned:")
    print(result)

    return result


@app.route('/map_categorical_values', methods=['POST'])
def map_categorical_values_route():
    data = request.json.get('data')
    column = request.json.get('column')
    unique_values = request.json.get('unique_values')
    standard_format = request.json.get('standard_format')

    # Debugging print statements for each variable
    print(f"Data received: {data}")
    print(f"Column received: {column}")
    print(f"Unique values received: {unique_values}")
    print(f"Standard format received: {standard_format}")

    # Call the mapping function and print the result for debugging
    result = map_categorical_values(data, column, unique_values, standard_format)
    print(f"Result of mapping: {result}")

    return jsonify(result)

@app.route('/delete_invalid_dates', methods=['POST'])
def delete_invalid_dates():
    data = request.json['data']
    date_format = request.json['dateFormat']  # Expected format for valid dates
    classifications = request.json['classifications']
    
    # Define format mappings for supported date formats
    format_mappings = {
        'mm/dd/yyyy': '%m/%d/%Y',
        'dd/mm/yyyy': '%d/%m/%Y',
        'yyyy/mm/dd': '%Y/%m/%d',
    }

    # Map date_format to the correct format string
    if date_format not in format_mappings:
        return jsonify({"error": f"Unsupported date format: {date_format}"}), 400

    # Set the target format string and additional formats to check
    target_format_str = format_mappings[date_format]
    alternative_formats = list(format_mappings.values())

    # Assume the first row is the header
    header = data[0]
    rows = data[1:]  # All rows except the header
    valid_data = [header]  # Start valid_data with the header

    # Identify indices of date columns based on classifications
    date_column_indices = [
        index for index, classification in enumerate(classifications)
        if classification[3] == 1  # 1 indicates it is a date column
    ]

    for row in rows:
        row_valid = True  # Assume row is valid initially
        for col_index in date_column_indices:
            value = row[col_index]
            if isinstance(value, str) and value.strip():  # Ensure it's a non-empty string
                valid_date = False

                # First, try parsing with the target format
                try:
                    datetime.strptime(value, target_format_str)
                    valid_date = True
                except ValueError:
                    # If the target format fails, try alternative formats
                    for fmt in alternative_formats:
                        try:
                            datetime.strptime(value, fmt)
                            valid_date = True
                            break
                        except ValueError:
                            continue
                
                # If no valid date format matches, mark the row as invalid
                if not valid_date:
                    print(f"Invalid date found: {value} in row {row}")
                    row_valid = False
                    break  # Stop checking further columns in this row
        if row_valid:
            valid_data.append(row)  # Only add rows that passed the check

    print(f"Valid data: {valid_data}")
    reformat_dates = reformat_date(valid_data, date_format, classifications)
    return jsonify(reformat_dates)

@app.route('/apply_letter_casing', methods=['POST'])
def apply_letter_casing_route():
    data = request.json['data']
    columns = request.json['columns']
    casing_selections = request.json['casingSelections']
    result = apply_letter_casing(data, columns, casing_selections)
    return jsonify(result)

@app.route('/apply_date_format', methods=['POST'])
def apply_date_format_route():
    data = request.json['data']
    columns = request.json['columns']
    date_formats = request.json['dateFormats']
    classifications = request.json['classifications']
    result = apply_date_format(data, columns, date_formats, classifications)
    return jsonify(result)

@app.route('/detect_issues', methods=['POST'])
def detect_issues_route():
    data = request.json['data']
    columns = request.json['columns']
    classifications = request.json['classifications']
    result = detect_issues(data, columns, classifications)
    return jsonify(result)

@app.route('/remove_columns', methods=['POST'])
def remove_columns():
    print('REMOVE COLUMNS')
    try:
        data = request.json.get('data')
        columns = request.json.get('columns')
        columns_to_remove = request.json.get('columnsToRemove', [])

        if not data or not columns:
            return jsonify({'error': 'No data or columns provided'}), 400
        if not columns_to_remove:
            return jsonify({'error': 'No columns specified to remove'}), 400

        # Convert the JSON data to a DataFrame
        df = pd.DataFrame(data[1:], columns=columns)

        # Drop duplicates
        df = df.drop_duplicates()

        # Remove the specified columns
        df_cleaned = df.drop(columns=columns_to_remove)

        # Convert the cleaned DataFrame back to JSON
        result_data = [df_cleaned.columns.tolist()] + df_cleaned.values.tolist()
        return jsonify(result_data)

    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/reformat_date', methods=['POST'])
def reformat_date_route():
    try:
        data = request.json['data']
        date_formats = request.json['dateFormats']
        classifications = request.json['classifications']
        print(f"Received data: {data}")
        print(f"Received dateFormats: {date_formats}")
        result = reformat_date(data, date_formats, classifications)  # Assuming you want the first date format
        return jsonify(result)
    except Exception as e:
        print(f"Error processing request: {e}")
        return jsonify({"error": str(e)}), 400

@app.route('/non_categorical_missing_values', methods=['POST'])
def process_data():
    print("Non-categorical-missingvlauesss")
    data = request.json
    column_name = data.get('column')  
    action = data.get('action')
    fill_value = data.get('fillValue')
    dataset = data.get('data')

    print(f"Column name: {column_name}")
    print(f"Data Received: {dataset}")

    if not dataset:
        return jsonify({"error": "No data provided"}), 400

    # Convert dataset to DataFrame, standardizing column names to lowercase
    df = pd.DataFrame(dataset[1:], columns=dataset[0]).replace("", np.nan)
    print(f"DataFrame Columns: {df.columns}")

    if action == "Remove Rows":
        print("Action: Remove Rows")

        if column_name not in df.columns:
            print("Column not found")
            return jsonify({"error": "Column not found"}), 400

        cleaned_df = df.dropna(subset=[column_name])
        cleaned_df = cleaned_df.where(pd.notnull(cleaned_df), None)
        cleaned_data = [list(cleaned_df.columns)] + cleaned_df.values.tolist()
        print(f"Cleaned Data (RemoveRows): {cleaned_data}")
        return jsonify(cleaned_data)

    elif action == "Fill with":
        column_index = None
        if dataset and column_name:
            header = [col.lower() for col in dataset[0]]
            if column_name in header:
                column_index = header.index(column_name)

        if column_index is None:
            return jsonify({"error": "Column not found"}), 400

        for row in dataset[1:]:
            if not row[column_index]: 
                row[column_index] = fill_value 

        print(f"Cleaned Data (Fill with): {dataset}")
        return jsonify(dataset)

    elif action == "Leave Blank":
        print(f"Cleaned Data (Leave Blank): {dataset}")
        return jsonify(dataset)

    else:
        return jsonify({"error": "Invalid action"}), 400

@app.route('/numerical_missing_values', methods=['POST'])
def numerical_missing_values():
    try:
        data = request.json
        column_name = data.get('column')
        action = data.get('action')
        fill_value = data.get('fillValue')
        dataset = data.get('data')
        print(f"NUMERICAL: {column_name}, FillValue {fill_value}, dataset: {dataset}")

        if not dataset or not column_name or not action:
            return jsonify({"error": "Missing required fields"}), 400

        # Convert dataset to DataFrame
        df = pd.DataFrame(dataset[1:], columns=dataset[0])
        df[column_name] = pd.to_numeric(df[column_name], errors='coerce')  # Convert column to numeric, non-numeric to NaN

        # Calculate mean, median, and mode ignoring NaN values
        mean_value = df[column_name].mean()
        median_value = df[column_name].median()
        try:
            mode_value = mode(df[column_name].dropna())
        except StatisticsError:
            mode_value = None  # Handle case where mode cannot be determined

        print(f"Mean: {mean_value}, Median: {median_value}, Mode: {mode_value}")

        # Handle the selected action
        if action == "Fill/Replace with Mean":
            df[column_name] = df[column_name].fillna(mean_value)
        elif action == "Fill/Replace with Median":
            df[column_name] = df[column_name].fillna(median_value)
        elif action == "Fill/Replace with Mode" and mode_value is not None:
            df[column_name] = df[column_name].fillna(mode_value)
        elif action == "Fill/Replace with Custom Value":
            try:
                custom_value = float(fill_value)
                df[column_name] = df[column_name].fillna(custom_value)
            except ValueError:
                return jsonify({"error": "Custom value must be a numeric value"}), 400
        elif action == "Remove Rows":
            df = df.dropna(subset=[column_name])
        elif action == "Leave Blank":
            # Do nothing, leave the values as they are
            pass
        else:
            return jsonify({"error": "Invalid action"}), 400

        # Replace NaN with None for JSON serialization
        cleaned_data = [list(df.columns)] + df.where(pd.notnull(df), None).values.tolist()

        return jsonify(cleaned_data)

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500
    
if __name__ == '__main__':
    # Set host to 0.0.0.0 to make it accessible on the network, port to 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
