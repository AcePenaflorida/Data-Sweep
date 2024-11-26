from statistics import StatisticsError, mode
import traceback
from flask import Flask, request, jsonify, send_file
import matplotlib
import pandas as pd
import numpy as np
import io
import seaborn as sns
import matplotlib.pyplot as plt
matplotlib.use('Agg')
from datetime import datetime
from scipy.stats import zscore
from sklearn.ensemble import IsolationForest
from sklearn.neighbors import LocalOutlierFactor
import statistics

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

@app.route('/apply_date_format', methods=['POST'])
def apply_date_format_route():
    data = request.json['data']
    columns = request.json['columns']
    date_formats = request.json['dateFormats']
    classifications = request.json['classifications']
    print(f"columns names: {columns}")
    print(f"Date formats: {date_formats}")
    print(f"classifications: {classifications}")
    result = apply_date_format(data, columns, date_formats, classifications)
    return jsonify(result)

def apply_date_format(data, columns, date_formats, classifications):
    # Define format mappings for supported date formats
    format_mappings = {
        'mm/dd/yyyy': '%m/%d/%Y',
        'dd/mm/yyyy': '%d/%m/%Y',
        'yyyy/mm/dd': '%Y/%m/%d',
    }

    # Loop over columns and rows to format dates in the specified columns
    for i in range(len(columns)):
        # Check if the column is classified as a date column
        if classifications[i][3] == 1:  # 1 indicates it is a date column
            # Get the date format for this specific column
            column_date_format = date_formats[i]
            if column_date_format not in format_mappings:
                raise ValueError(f"Unsupported date format: {column_date_format}")

            # Get the corresponding format string for the target column date format
            target_format_str = format_mappings[column_date_format]
            print(f"Target format for column {i}: {target_format_str}")

            for j in range(len(data)):
                value = data[j][i]

                # Ensure the value is a string (only try to parse string dates)
                if isinstance(value, str):
                    # Replace hyphens with slashes to conform to the target format
                    value = value.replace('-', '/')

                    # Now, we don't need to parse it as an actual date, just format it
                    data[j][i] = value  # Ensure the date is in the target format

                    # Optionally, print any invalid dates (for debugging purposes)
                    if not is_valid_date(value, target_format_str):
                        print(f"Invalid date format for value: {value}")

    return data

# Helper function to validate the date format
def is_valid_date(value, format_str):
    try:
        datetime.strptime(value, format_str)
        return True
    except ValueError:
        return False



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
    headers = [header for header in headers]
    column = column

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

def calculate_iqr_thresholds(series):
    q1 = series.quantile(0.25)
    q3 = series.quantile(0.75)
    iqr = q3 - q1
    outlier_threshold_lower = q1 - 1.5 * iqr
    outlier_threshold_upper = q3 + 1.5 * iqr
    return outlier_threshold_lower, outlier_threshold_upper


def choose_outlier_detection_method(df, column):
    skewness = df[column].skew()
    is_normal = abs(skewness) < 0.5
    is_high_dimensional = len(df.columns) > 10
    is_clustered = len(np.unique(df[column])) > 10

    if is_normal:
        print("Data is normally distributed. Using Z-score for outlier detection.")
        return 'Z-score'
    elif not is_normal and not is_high_dimensional:
        print("Data is skewed. Using IQR for outlier detection.")
        return 'IQR'
    elif is_high_dimensional:
        print("Data is high-dimensional. Using Isolation Forest for outlier detection.")
        return 'Isolation Forest'
    elif is_clustered:
        print("Data has clusters. Using Local Outlier Factor (LOF) for outlier detection.")
        return 'LOF'
    else:
        print("Using default method: IQR.")
        return 'IQR'

def choose_xscale(df, column):
    # Count the number of data points
    num_points = df[column].count()
    data_range = df[column].max() - df[column].min()
    
    # Check if the data contains negative or zero values
    has_negatives = (df[column] < 0).any()
    has_zeros = (df[column] == 0).any()

    # Decide on the scale based on dataset size and properties
    if has_negatives:
        # Use 'symlog' if there are negative values
        return 'symlog'
    elif has_zeros:
        # Avoid 'log' if there are zeros
        return 'symlog' if num_points > 500 else 'linear'
    else:
        # Use 'log' if the data spans several orders of magnitude and no zeros/negatives
        if data_range > 1000 and num_points > 100:
            return 'log'
        # For small data ranges or small dataset sizes, use 'linear'
        return 'linear' if num_points < 100 else 'log'
    
def plot_boxen_with_outliers(df, column, method):
    if method == 'Z-score':
        z_scores = zscore(df[column])
        outliers = df[np.abs(z_scores) > 3]
    elif method == 'IQR':
        lower_limit, upper_limit = calculate_iqr_thresholds(df[column])
        outliers = df[(df[column] < lower_limit) | (df[column] > upper_limit)]
    elif method == 'Isolation Forest':
        model = IsolationForest()
        outlier_preds = model.fit_predict(df[[column]])
        outliers = df[outlier_preds == -1]
    elif method == 'LOF':
        model = LocalOutlierFactor()
        outlier_preds = model.fit_predict(df[[column]])
        outliers = df[outlier_preds == -1]

    normal_data = df[~df.index.isin(outliers.index)]
    num_points = len(df)
    point_size = 10 if num_points > 500 else 30
    fig_width = 10 if num_points > 500 else 5

    plt.figure(figsize=(fig_width, 6))
    sns.boxenplot(data=df, x=column, color="green", showfliers=False)
    sns.scatterplot(data=normal_data, x=column, y=[0] * len(normal_data), color='blue', s=point_size, label='Normal Data')
    sns.scatterplot(data=outliers, x=column, y=[0] * len(outliers), color='red', s=point_size * 1.5, label='Outliers')

    scale = choose_xscale(df, column)
    plt.xscale(scale)

    plt.title(f'{scale.upper()} Scale Plot for {column} (Total: {num_points} values, {len(outliers)} outliers)')

    # Save the plot to a BytesIO object and return it
    img = io.BytesIO()
    plt.savefig(img, format='png')
    img.seek(0)
    plt.close()  # Close the plot to free memory
    return img, len(outliers)

def filter_outliers_by_z_score(df, column):
    lower_limit, upper_limit = calculate_iqr_thresholds(df[column])
    new_df = df.loc[(df[column] < upper_limit) & (df[column] > lower_limit)]
    return new_df

def cap_and_floor(df, column):
    lower_limit, upper_limit = calculate_iqr_thresholds(df[column])
    df[column] = df[column].apply(
        lambda x: upper_limit if x > upper_limit else (lower_limit if x < lower_limit else x)
    )
    return df

def replace_with_mean(df, column):
    lower_limit, upper_limit = calculate_iqr_thresholds(df[column])
    column_mean = df[column].mean()
    df[column] = df[column].apply(
        lambda x: column_mean if x > upper_limit or x < lower_limit else x
    )
    return df

def replace_with_median(df, column):
    lower_limit, upper_limit = calculate_iqr_thresholds(df[column])
    column_median = df[column].median()
    df[column] = df[column].apply(
        lambda x: column_median if x > upper_limit or x < lower_limit else x
    )
    return df

@app.route('/scale_features', methods=['POST'])
def scale_features():
    data = request.json.get('data')
    numerical_columns = request.json.get('numerical_columns')
    scaling_methods = request.json.get('scaling_methods')

    df = pd.DataFrame(data[1:], columns=data[0])  # Convert to DataFrame using headers from the first row

    # Apply the scaling method for each numerical column
    for col in numerical_columns:
        method = scaling_methods.get(col, 'None')
        if method == 'Normalization':
            if col in df.columns:
                df[col] = (df[col] - df[col].min()) / (df[col].max() - df[col].min())
        elif method == 'Standardization':
            if col in df.columns:
                df[col] = (df[col] - df[col].mean()) / df[col].std()

    # Convert the DataFrame back to a list of lists, including the column names
    scaled_data = df.values.tolist()
    combined_data = [df.columns.tolist()] + scaled_data

    return jsonify(combined_data)




@app.route('/outliers_graph', methods=['POST'])
def outliers_graph():
    data = request.json.get('data')
    column_name = request.json.get('column_name')
    task = request.json.get('task')
    method = request.json.get('method')
    df = pd.DataFrame(data[1:], columns=data[0])
    print(f"column_name: {column_name}")
    print(f"data: {data}")

    outlier_detection_method = choose_outlier_detection_method(df, column_name)
    outliers_count = 1
    filtered_outliers = df.copy()

    if(task == "Show Outliers" and method == ""):
        img, outliers_count = plot_boxen_with_outliers(df, column_name, outlier_detection_method)
        print(f"Outliers: {outliers_count}")

    elif task == "Resolve Outliers":
        while outliers_count != 0:
            if method == "Remove":
                filtered_outliers = filter_outliers_by_z_score(filtered_outliers, column_name)
            elif method == "Cap and Floor":
                filtered_outliers = cap_and_floor(filtered_outliers, column_name)
            elif method == "Replace with Mean":
                filtered_outliers = replace_with_mean(filtered_outliers, column_name)
            elif method == "Replace with Median":
                filtered_ouliters = replace_with_median(filtered_outliers, column_name)
            
            img, outliers_count = plot_boxen_with_outliers(filtered_outliers, column_name, outlier_detection_method)
    
    return send_file(img, mimetype='image/png', as_attachment=True, download_name='outliers.png')

@app.route('/get_cleaned_file', methods=['POST'])
def get_cleaned_file():
    data = request.json.get('data')
    column_name = request.json.get('column_name')
    task = request.json.get('task')
    method = request.json.get('method')
    print(data)

    df = pd.DataFrame(data[1:], columns=data[0])
    outlier_detection_method = choose_outlier_detection_method(df, column_name)
    filtered_outliers = df.copy()

    # Apply the selected outlier removal method
    if task == "Resolve Outliers":
        if method == "Remove":
            filtered_outliers = filter_outliers_by_z_score(filtered_outliers, column_name)
        elif method == "Cap and Floor":
            filtered_outliers = cap_and_floor(filtered_outliers, column_name)
        elif method == "Replace with Mean":
            filtered_outliers = replace_with_mean(filtered_outliers, column_name)
        elif method == "Replace with Median":
            filtered_outliers = replace_with_median(filtered_outliers, column_name)
    
    # Convert cleaned data to a list of lists (for JSON serialization)
    cleaned_data = [filtered_outliers.columns.tolist()] + filtered_outliers.values.tolist()
    
    # Return both the cleaned data and the column names
    
    return jsonify(cleaned_data)

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

@app.route('/show_invalid_dates', methods=['POST'])
def show_invalid_dates():
    data = request.json['data']
    date_format = request.json['dateFormat']  # Get the user-specified date format
    classifications = request.json['classifications']
    column_index = request.json['columnIndex']  # Get the specific column to check

    # Print out the received values to debug
    print(f"Received Date Format: {date_format}")
    print(f"Received Column Index: {column_index}")
    print(f"Received Classifications: {classifications}")

    # Define format mappings for supported date formats
    format_mappings = {
        'mm/dd/yyyy': '%m/%d/%Y',
        'dd/mm/yyyy': '%d/%m/%Y',
        'yyyy/mm/dd': '%Y/%m/%d',
        'dd-mm-yyyy': '%d-%m-%Y',
    }

    # Ensure the chosen date format is supported
    if date_format not in format_mappings:
        return jsonify({"error": f"Unsupported date format: {date_format}"}), 400

    # Get the correct format string for the user's choice
    target_format_str = format_mappings[date_format]
    print(f"Target Format for Validation: {target_format_str}")  # Print the target format to debug
    invalid_dates = []

    # Iterate through the dataset and check the specific column, ignoring the first row
    for index, row in enumerate(data):
        if index == 0:  # Skip the first row (assumed to be the header)
            continue

        value = row[column_index]
        if isinstance(value, str) and value.strip():  # Ensure it's a non-empty string
            try:
                # Try parsing the date using the user's chosen format
                parsed_date = datetime.strptime(value, format_mappings[date_format])  # Use the chosen format
                formatted_date = parsed_date.strftime(target_format_str)  # Format date to target format
                row[column_index] = formatted_date
            except ValueError:
                # If parsing fails, mark it as invalid
                invalid_dates.append({
                    "invalid_date": value,
                    "expected_format": target_format_str
                })

    # Return invalid dates in the specified format
    return jsonify({"invalid_dates": invalid_dates})

@app.route('/reformat_column', methods=['POST'])
def reformat_column():
    data = request.json['data']
    date_format = request.json['dateFormat']  
    classifications = request.json['classifications']
    column_index = request.json['columnIndex']  # Get the column to reformat

    # Define format mappings for supported date formats
    format_mappings = {
        'mm/dd/yyyy': '%m/%d/%Y',
        'dd/mm/yyyy': '%d/%m/%Y',
        'yyyy/mm/dd': '%Y/%m/%d',
    }

    # Ensure the chosen date format is supported
    if date_format not in format_mappings:
        return jsonify({"error": f"Unsupported date format: {date_format}"}), 400

    target_format_str = format_mappings[date_format]

    # Create a list of indices to delete invalid rows
    invalid_row_indices = []

    # Iterate over the data and reformat the selected column
    for index, row in enumerate(data):
        if index == 0:  # Skip the first row (assumed to be the header)
            continue

        value = row[column_index]
        if isinstance(value, str) and value.strip():
            try:
                # Try parsing the date using multiple formats
                parsed_date = None
                for fmt in format_mappings.values():
                    try:
                        parsed_date = datetime.strptime(value, fmt)
                        break
                    except ValueError:
                        continue

                if parsed_date:
                    # If parsing is successful, reformat the date
                    row[column_index] = parsed_date.strftime(target_format_str)
                else:
                    # Mark row for deletion if date is invalid
                    invalid_row_indices.append(index)
            except ValueError:
                # Mark row for deletion if parsing fails
                invalid_row_indices.append(index)

    # Delete rows with invalid dates
    data = [row for index, row in enumerate(data) if index not in invalid_row_indices]

    print(data)  # Optionally log the updated data for debugging
    return jsonify(data)



@app.route('/non_categorical_missing_values', methods=['POST'])
def process_data():
    print("YOU GOT HERE")
    data = request.json
    column_name = data.get('column')
    action = data.get('action')
    fill_value = data.get('fillValue')
    dataset = data.get('data')
    print(fill_value)

    if not dataset:
        return jsonify({"error": "No data provided"}), 400

    # Create a DataFrame and replace empty strings with NaN
    df = pd.DataFrame(dataset[1:], columns=dataset[0]).replace("", np.nan)
    print(f"DataFrame Columns: {df.columns}")

    if column_name not in df.columns:
        return jsonify({"error": "Column not found"}), 400

    if action == "Remove Rows":
        print("Action: Remove Rows")
        cleaned_df = df.dropna(subset=[column_name])
        cleaned_df = cleaned_df.applymap(lambda x: "" if pd.isna(x) else x)
        cleaned_data = [list(cleaned_df.columns)] + cleaned_df.values.tolist()
        print(f"Cleaned Data (Remove Rows): {cleaned_data}")
        return jsonify(cleaned_data)

    elif action == "Fill with":
        if fill_value is None or fill_value == "": 
            fill_value = ""  # or set a default value
        column_index = dataset[0].index(column_name)  # Get column index from header
        print(f"Column Index: {column_index}")

        for row in dataset[1:]:
            if row[column_index] in [None, ""]:  # If the value is missing
                row[column_index] = fill_value
        
        print(f"Cleaned Data (Fill with): {dataset}")
        return jsonify(dataset)

    elif action == "Fill with Mode":
        print("Action: Fill with Mode")
        mode_value = df[column_name].mode().iloc[0] if not df[column_name].mode().empty else ""
        print(f"Mode Value for {column_name}: {mode_value}")

        df[column_name] = df[column_name].fillna(mode_value)
        filled_data = [list(df.columns)] + df.applymap(lambda x: "" if pd.isna(x) else x).values.tolist()
        print(f"Cleaned Data (Fill with Mode): {filled_data}")
        return jsonify(filled_data)

    elif action == "Leave Blank":
        print(f"Cleaned Data (Leave Blank): {dataset}")
        return jsonify(dataset)

    else:
        return jsonify({"error": "Invalid action"}), 400



# @app.route('/get_column_dtype', methods=['POST'])
# def get_majority_dtype():
#     print("Function Invoked: get_majority_dtype")
#     data = request.json('data')
#     columnName = request.json('columnName')

#     # returns the specific column
#     column = map_column_in_dataset(data, columnName)
#     column_cleaned = column.dropna()
    
#     # Check for numerical values
#     try:
#         numeric_column = pd.to_numeric(column_cleaned, errors='coerce')
#         numeric_count = numeric_column.notna().sum()
#     except Exception:
#         numeric_count = 0
    
#     # Check for date values
#     try:
#         date_column = pd.to_datetime(column_cleaned, errors='coerce')
#         date_count = date_column.notna().sum()
#     except Exception:
#         date_count = 0
    
#     # Count non-numeric, non-date values
#     non_numeric_non_date_count = len(column_cleaned) - numeric_count - date_count
    
#     # Determine majority type
#     type_counts = {
#         'numeric': numeric_count,
#         'date': date_count,
#         'non-numeric': non_numeric_non_date_count
#     }
    
#     majority_type = max(type_counts, key=type_counts.get)
    
#     return jsonify(majority_type)

# def convert_numeric_values(value):
#     try:
#         # If the value can be converted to a number, return the numeric value (either int or float)
#         return pd.to_numeric(value, errors='raise')
    
#     except:
#         # If it cannot be converted (e.g., it's a string like 'ace'), return the original value
#         return value

# def map_column_in_dataset(data, columnName):
#     # Apply the conversion function to each element in the specified column of the DataFrame
#     data[columnName] = data[columnName].apply(convert_numeric_values)
#     return data[columnName].tolist()




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
    
def generate_chart(column_name, column_data, classification):
    chart_type = None
    if classification[0] == 1:
        chart_type = 'numerical'
    elif classification[1] == 1:
        chart_type = 'categorical'
    elif classification[2] == 1:
        chart_type = 'non-categorical'
    elif classification[3] == 1:
        chart_type = 'date'

    # Create the appropriate plot based on classification
    fig, ax = plt.subplots()

    if chart_type == 'numerical':
        # Ensure only valid numeric entries
        column_data = [
            float(i) if isinstance(i, (int, float)) else None
            for i in column_data if i != '' and i is not None
        ]
        # Remove any None values
        column_data = [i for i in column_data if i is not None]
        
        ax.hist(column_data, bins=20, edgecolor='black')  # You can adjust the number of bins
        ax.set_title(f"Numerical Data: {column_name}")
        ax.set_xlabel('Value')
        ax.set_ylabel('Frequency')

    elif chart_type == 'categorical':
        column_data = column_data[1:]
        # Count the occurrences of each category
        category_counts = pd.Series(column_data).value_counts()
        
        # Plot as a pie chart
        ax.pie(category_counts, labels=category_counts.index, autopct='%1.1f%%', startangle=90)
        ax.set_title(f"Categorical Data: {column_name}")
        ax.axis('equal')

    elif chart_type == 'non-categorical':
        # Count the non-empty values and missing (null/empty) values
        non_empty_values = [val for val in column_data if val != '' and val is not None]
        missing_values = len(column_data) - len(non_empty_values)

        ax.bar(['Non-Empty', 'Missing'], [len(non_empty_values), missing_values])
        ax.set_title(f"Non-Categorical Data: {column_name}")
        ax.set_ylabel('Count')

    elif chart_type == 'date':
        dates = pd.to_datetime(column_data, errors='coerce')
        
        if dates.isnull().all():
            ax.text(0.5, 0.5, "No valid dates available", ha='center', va='center', fontsize=12)
        else:
            # Use a line plot instead of scatter
            ax.plot(dates, range(len(dates)), linestyle='-', color='teal', marker='o')
            ax.set_title(f"Date Data: {column_name}")
            ax.set_xlabel('Date')
            ax.set_ylabel('Index')

    # Save the plot to a byte stream
    img_stream = io.BytesIO()
    fig.savefig(img_stream, format='png')
    img_stream.seek(0)
    plt.close(fig)

    return img_stream

@app.route('/generate-chart', methods=['POST'])
def generate_chart_endpoint():
    # Receive JSON data
    data = request.json.get('data')
    columns = request.json.get('columns')
    classifications = request.json.get('classifications')
    column_name = request.json.get('column_name')

    # Check the structure of 'data'
    if isinstance(data, str):  # If data is a string, parse it
        import json
        data = json.loads(data)

    if data and classifications and columns and column_name:
        try:
            column_index = columns.index(column_name)  # Find the index of the column
        except ValueError:
            print(f"Column '{column_name}' not found in columns list.")
            return f"Column '{column_name}' not found in the columns list", 400
        
        # Ensure that 'csv_data' is a list of lists
        column_data = [row[column_index] for row in data.get("csv_data", [])]
        classification = classifications[column_index]

        # Generate the chart
        img = generate_chart(column_name, column_data, classification)
        return send_file(img, mimetype='image/png')
    else:
        print("Missing parameters.")
        return "Missing parameters", 400

@app.route('/calculate-statistics', methods=['POST'])
def calculate_statistics():
    # Ensure that the data is parsed as JSON into a Python dictionary
    data = request.json.get('data')  # Assuming the data is under 'csv_data'
    columns = request.json.get('columns')
    classifications = request.json.get('classifications')
    column_name = request.json.get('column_name')
    # Ensure the column_name exists in the columns list
    if column_name not in columns:
        return jsonify({"error": f"Column '{column_name}' not found in columns list"}), 400

    # Find the index of the column in the columns list
    column_index = columns.index(column_name)

    column_data = [row[column_index] for row in data[1:]] 

    classification = classifications[column_index]
    print("Classification for the column:", classification)


    if classification[2] == 1:  # non-categorical

        non_empty_values = [value for value in column_data if value != '' and value is not None]
        missing_values = len(column_data) - len(non_empty_values)
        return jsonify({
            "non_empty_count": len(non_empty_values),
            "missing_count": missing_values
        })
    
    if classification[3] == 1:  # date
        # No statistics to calculate for date type
        return jsonify({
            "message": "No statistics available for date type."
        })
    
    if classification[0] == 1:  # numerical
    # Try to convert the column data to numerical values (float), skipping invalid or missing values
        column_data_filtered = []
        for value in column_data:
            try:
                # Attempt to convert each value to a float, and skip invalid ones
                numeric_value = float(value)
                column_data_filtered.append(numeric_value)
            except (ValueError, TypeError):
                # Skip invalid values (e.g., strings, None, or empty values)
                continue
        
        # Debugging: Print the filtered data
        print(f"Filtered numeric column_data: {column_data_filtered}")

        # Check if column_data_filtered is empty after filtering
        if not column_data_filtered:
            return jsonify({"error": "No valid numeric data found in column"}), 400
        
        # Calculate statistics (mean, median, mode)
        mean = np.mean(column_data_filtered)
        median = np.median(column_data_filtered)
        try:
            mode = statistics.mode(column_data_filtered)
        except statistics.StatisticsError:
            mode = "No unique mode"
        
        return jsonify({
            "mean": mean,
            "median": median,
            "mode": mode
        })


    if classification[1] == 1:  # categorical
        # For categorical data, calculate the mode and count of each unique value
        mode = statistics.mode(column_data) if column_data else None
        value_counts = {value: column_data.count(value) for value in set(column_data)}
        
        return jsonify({
            "mode": mode,
            "value_counts": value_counts
        })
    
    # Default return if no matching classification
    return jsonify({
        "error": "Invalid column classification"
    })


if __name__ == '__main__':

    app.run(host='0.0.0.0', port=5000, debug=True)
