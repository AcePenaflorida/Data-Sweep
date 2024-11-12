import traceback
from flask import Flask, request, jsonify, send_file
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
    for i in range(len(columns)):
        casing = casing_selections[i]
        for j in range(len(data)):
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
    
# def reformat_date(data, date_format):
#     # Define format mappings for supported date formats
#     format_mappings = {
#         'mm/dd/yyyy': '%m/%d/%Y',   # Correct mapping for month/day/year
#         'dd/mm/yyyy': '%d/%m/%Y',   # Correct mapping for day/month/year
#         'yyyy/mm/dd': '%Y/%m/%d',   # Correct mapping for year/month/day
#     }
#     print(f"reformat_date: {date_format}")

#     # Check if the date format is supported
#     if date_format not in format_mappings:
#         raise ValueError(f"Unsupported date format: {date_format}")

#     # Get the datetime format string based on the provided date format
#     date_format_str = format_mappings[date_format]

#     print(f"Target Format: {date_format_str}")

#     # Iterate over the rows and columns to reformat the dates
#     for row in data:
#         for i, value in enumerate(row):
#             if isinstance(value, str):
#                 print(f"Original Value: {value}")
#                 try:
#                     # Try to parse and reformat the date (assuming the date is in '%Y-%m-%d' format)
#                     parsed_date = datetime.strptime(value, '%Y-%m-%d')  # Original expected format
#                     print(f"Parsed Date: {parsed_date}")
                    
#                     reformatted_date = parsed_date.strftime(date_format_str)  # Reformat to the target format
#                     print(f"Reformatted Date: {reformatted_date}")

#                     row[i] = reformatted_date  # Update the row with the reformatted date
#                 except ValueError as e:
#                     print(f"Skipping value '{value}' due to error: {e}")
#                     pass  # Skip if the value can't be parsed as a date

#     return data

def reformat_date(data, date_format):
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

    # Iterate over the rows and columns to reformat the dates
    for row in data:
        for i, value in enumerate(row):
            if isinstance(value, str):
                print(f"Original Value: {value}")
                parsed_date = None

                # Try parsing the date using multiple possible formats
                for fmt in format_mappings.values():
                    try:
                        parsed_date = datetime.strptime(value, fmt)
                        print(f"Parsed Date with format '{fmt}': {parsed_date}")
                        break  # Stop on first successful parse
                    except ValueError:
                        continue  # Try the next format if parsing fails

                # If parsed successfully, reformat to the target format
                if parsed_date:
                    reformatted_date = parsed_date.strftime(target_format_str)
                    print(f"Reformatted Date: {reformatted_date}")
                    row[i] = reformatted_date
                else:
                    print(f"Skipping value '{value}' due to unrecognized date format.")

    return data

# def apply_date_format(data, columns, date_format, classifications):
#     # Define format mappings for supported date formats
#     format_mappings = {
#         'mm/dd/yyyy': '%m/%d/%Y',
#         'dd/mm/yyyy': '%d/%m/%Y',
#         'yyyy/mm/dd': '%Y/%m/%d',
#     }

#     # Check if the date format is supported once outside the loop
#     # selectedFormat = date_format[2]
#     if date_format not in format_mappings:
#         raise ValueError(f"Unsupported date format: {date_format}")

#     # Get the corresponding format string
#     format_str = format_mappings[date_format]
#     print(format_str)

#     # Loop over columns and rows to format dates in the specified columns
#     for i in range(len(columns)):
#         # Check if the column is classified as a date column
#         if classifications[i][3] == 1:  # 1 indicates it is a date column
#             for j in range(len(data)):
#                 value = data[j][i]

#                 # Ensure the value is a string (only try to parse string dates)
#                 if isinstance(value, str):
#                     try:
#                         # Parse the date assuming the input format is YYYY-MM-DD
#                         date_obj = datetime.strptime(value, "%Y-%m-%d")
#                         # Format the date according to the specified format
#                         data[j][i] = date_obj.strftime(format_str)
#                     except ValueError:
#                         # If parsing fails, replace with np.nan
#                         pass

#     return data

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


# def delete_invalid_dates():
#     data = request.json['data']
#     date_format = request.json['dateFormat']  # Expected format for valid dates

#     format_mappings = {
#         'mm/dd/yyyy': '%m/%d/%Y',
#         'dd/mm/yyyy': '%d/%m/%Y',
#         'yyyy/mm/dd': '%Y/%m/%d',
#     }

#     # Map date_format to the correct format string
#     if date_format not in format_mappings:
#         return jsonify({"error": f"Unsupported date format: {date_format}"}), 400

#     date_format_str = format_mappings[date_format]
#     print(f"Target Format: {date_format_str}")
#     valid_data = []

#     for row in data:
#         row_valid = True
#         for value in row:
#             if isinstance(value, str):
#                 try:
#                     parsed_date = datetime.strptime(value, '%Y-%m-%d') 
#                     print(f"Parsed Date: {parsed_date}")
#                     reformatted_date = parsed_date.strftime(date_format_str) 
                    
#                 except ValueError:
#                     row_valid = False
#                     break
#         if row_valid:
#             valid_data.append(row)

#     return jsonify(valid_data)
# @app.route('/delete_invalid_dates', methods=['POST'])
# def delete_invalid_dates():
#     data = request.json['data']
#     date_format = request.json['dateFormat']  # Expected format for valid dates
#     columns = request.json['columns']
#     classifications = request.json['classifications']
#     format_mappings = {
#         'mm/dd/yyyy': '%m/%d/%Y',
#         'dd/mm/yyyy': '%d/%m/%Y',
#         'yyyy/mm/dd': '%Y/%m/%d',
#     }

#     # Map date_format to the correct format string
#     if date_format not in format_mappings:
#         return jsonify({"error": f"Unsupported date format: {date_format}"}), 400

#     date_format_str = format_mappings[date_format]
#     print(f"Target Format: {date_format_str}")

#     # Assume the first row is the header
#     header = data[0]
#     rows = data[1:]  # All rows except the header
#     valid_data = [header]  # Start valid_data with the header

#     for row in rows:
#         row_valid = True
#         for value in row:
#             if isinstance(value, str):
#                 try:
#                     parsed_date = datetime.strptime(value, '%Y-%m-%d') 
#                     print(f"Parsed Date: {parsed_date}")
#                     reformatted_date = parsed_date.strftime(date_format_str) 
#                 except ValueError:
#                     row_valid = False
#                     break
#         if row_valid:
#             valid_data.append(row)

#     return jsonify(valid_data)


# @app.route('/delete_invalid_dates', methods=['POST'])
# def delete_invalid_dates():
#     data = request.json['data']
#     date_format = request.json['dateFormat']  # Expected format for valid dates
#     classifications = request.json['classifications']
    
#     # Define format mappings for supported date formats
#     format_mappings = {
#         'mm/dd/yyyy': '%m/%d/%Y',
#         'dd/mm/yyyy': '%d/%m/%Y',
#         'yyyy/mm/dd': '%Y/%m/%d',
#     }

#     # Map date_format to the correct format string
#     if date_format not in format_mappings:
#         return jsonify({"error": f"Unsupported date format: {date_format}"}), 400

#     date_format_str = format_mappings[date_format]
#     print(f"Target Format: {date_format_str}")

#     # Assume the first row is the header
#     header = data[0]
#     rows = data[1:]  # All rows except the header
#     valid_data = [header]  # Start valid_data with the header

#     # Identify indices of date columns based on classifications
#     date_column_indices = [
#         index for index, classification in enumerate(classifications)
#         if classification[3] == 1  # 1 indicates it is a date column
#     ]
#     print(f"Date columns indices: {date_column_indices}")

#     for row in rows:
#         row_valid = True  # Assume row is valid initially
#         for col_index in date_column_indices:
#             value = row[col_index]
#             if isinstance(value, str) and value:  # Ensure it's a non-empty string
#                 try:
#                     parsed_date = datetime.strptime(value, '%Y-%m-%d') 
#                     print(f"Parsed Date: {parsed_date}")
#                     reformatted_date = parsed_date.strftime(date_format_str) 
#                 except ValueError:
#                     print(f"Invalid date found: {value} in row {row}")
#                     row_valid = False  # Mark row as invalid if parsing fails
#                     value = ""
#                     break  # Stop checking further columns in this row
#         if row_valid:
#             valid_data.append(row)  # Only add rows that passed the check

#     print(f"Valid data: {valid_data}")
#     reformat_valid = reformat_date(valid_data, date_format)
#     return jsonify(reformat_valid)

@app.route('/delete_invalid_dates', methods=['POST'])
# def delete_invalid_dates():
#     data = request.json['data']
#     date_format = request.json['dateFormat']  # Expected format for valid dates
#     classifications = request.json['classifications']
    
#     # Define format mappings for supported date formats
#     format_mappings = {
#         'mm/dd/yyyy': '%m/%d/%Y',
#         'dd/mm/yyyy': '%d/%m/%Y',
#         'yyyy/mm/dd': '%Y/%m/%d',
#     }

#     # Map date_format to the correct format string
#     if date_format not in format_mappings:
#         return jsonify({"error": f"Unsupported date format: {date_format}"}), 400

#     # Set the target format string and additional formats to check
#     target_format_str = format_mappings[date_format]
#     alternative_formats = list(format_mappings.values())

#     # Assume the first row is the header
#     header = data[0]
#     rows = data[1:]  # All rows except the header
#     valid_data = [header]  # Start valid_data with the header

#     # Identify indices of date columns based on classifications
#     date_column_indices = [
#         index for index, classification in enumerate(classifications)
#         if classification[3] == 1  # 1 indicates it is a date column
#     ]

#     for row in rows:
#         row_valid = True  # Assume row is valid initially
#         for col_index in date_column_indices:
#             value = row[col_index]
#             if isinstance(value, str) and value:  # Ensure it's a non-empty string
#                 valid_date = False
#                 for fmt in alternative_formats:
#                     try:
#                         # Attempt to parse the date with each format
#                         datetime.strptime(value, fmt)
#                         valid_date = True
#                         break
#                     except ValueError:
#                         continue
#                 if not valid_date:
#                     print(f"Invalid date found: {value} in row {row}")
#                     row_valid = False  # Mark row as invalid if all attempts fail
#                     break  # Stop checking further columns in this row
#         if row_valid:
#             valid_data.append(row)  # Only add rows that passed the check

#     print(f"Valid data: {valid_data}")
#     return jsonify(valid_data)
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
    reformat_dates = reformat_date(valid_data, date_format)
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
    try:
        file = request.files['file']
        columns_to_remove = request.form.get('columns', '').split(',')
        
        # Ensure the columns list is not empty
        if not columns_to_remove or columns_to_remove == ['']:
            return jsonify({'error': 'No columns specified to remove'}), 400

        # Read the CSV file
        df = pd.read_csv(file)
        
        #drop duplicates
        df = df.drop_duplicates()
        
        # Drop specified columns
        df_cleaned = df.drop(columns=columns_to_remove)
        
        # Save the cleaned file into a BytesIO object (binary mode)
        cleaned_file = io.BytesIO()
        df_cleaned.to_csv(cleaned_file, index=False)
        cleaned_file.seek(0)  # Rewind the file to the beginning

        # Send the cleaned file back as a response
        return send_file(
            cleaned_file,
            mimetype='text/csv',
            as_attachment=True,
            download_name='cleaned_file.csv'
        )
        
    except Exception as e:
        # Log the exception to see what went wrong
        print(f"Error: {str(e)}")
        print("Detailed traceback:")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@app.route('/reformat_date', methods=['POST'])
def reformat_date_route():
    try:
        data = request.json['data']
        date_formats = request.json['dateFormats']
        print(f"Received data: {data}")
        print(f"Received dateFormats: {date_formats}")
        result = reformat_date(data, date_formats)  # Assuming you want the first date format
        return jsonify(result)
    except Exception as e:
        print(f"Error processing request: {e}")
        return jsonify({"error": str(e)}), 400



if __name__ == '__main__':
    # Set host to 0.0.0.0 to make it accessible on the network, port to 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
