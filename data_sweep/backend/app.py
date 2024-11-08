from flask import Flask, request, jsonify, send_file
import pandas as pd
import io
import traceback

app = Flask(__name__)

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

if __name__ == '__main__':
    # Set host to 0.0.0.0 to make it accessible on the network, port to 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
